import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import 'package:kasir_cepat/feature/shift/domain/entities/shift.dart';
import 'provider/report_provider.dart';

class ShiftReportPage extends ConsumerStatefulWidget {
  const ShiftReportPage({super.key});

  @override
  ConsumerState<ShiftReportPage> createState() => _ShiftReportPageState();
}

class _ShiftReportPageState extends ConsumerState<ShiftReportPage> {
  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(reportShiftsListProvider);
    final selectedShiftId = ref.watch(selectedShiftIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Per Shift',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: shiftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Gagal memuat daftar shift: $err', textAlign: TextAlign.center),
          ),
        ),
        data: (shifts) {
          if (shifts.isEmpty) {
            return _buildEmptyState(message: 'Belum ada riwayat shift yang terdaftar.');
          }

          // Auto-select latest shift if none selected
          final activeId = selectedShiftId ?? shifts.first.id;
          if (selectedShiftId == null && activeId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedShiftIdProvider.notifier).state = activeId;
            });
          }

          return Column(
            children: [
              // Shift Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.history, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pilih Sesi Shift:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: activeId,
                          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          items: shifts.map((s) {
                            final dateLabel = DateFormat('dd MMM, HH:mm').format(s.startTime);
                            final statusLabel = s.status == ShiftStatus.open ? 'Aktif' : 'Tutup';
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text('Shift #${s.id} ($dateLabel) - $statusLabel'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(selectedShiftIdProvider.notifier).state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detail shift report content
              Expanded(
                child: activeId == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ref.watch(shiftReportProvider(activeId)).when(
                          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text('Gagal memuat laporan shift: $err', textAlign: TextAlign.center),
                            ),
                          ),
                          data: (report) => RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              ref.invalidate(shiftReportProvider(activeId));
                              ref.invalidate(reportShiftsListProvider);
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.all(20),
                              children: [
                                // Metadata header card
                                _buildMetadataCard(report),
                                const SizedBox(height: 20),

                                // Cash reconciliation
                                _buildReconciliationCard(report),
                                const SizedBox(height: 20),

                                // Sales & performance summary
                                _buildPerformanceCard(report),
                                const SizedBox(height: 20),

                                // Payment breakdown
                                _buildPaymentBreakdownCard(report),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetadataCard(dynamic report) {
    final isOpen = report.status == 'open';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift #${report.shiftId}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? 'AKTIF (BERJALAN)' : 'SUDAH TUTUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(LucideIcons.user, 'Kasir', report.cashierName ?? 'Tidak Diketahui'),
          const SizedBox(height: 8),
          _buildInfoRow(LucideIcons.playCircle, 'Mulai', _formatDateTime(report.startTime)),
          const SizedBox(height: 8),
          _buildInfoRow(LucideIcons.stopCircle, 'Selesai', isOpen ? 'Masih Aktif' : _formatDateTime(report.endTime)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildReconciliationCard(dynamic report) {
    final isOpen = report.status == 'open';
    final expectedTotalCash = report.cashStart + report.totalSales; // start cash + expected sales

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekonsiliasi Kas Laci',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            label: 'Modal Awal',
            value: _formatCurrency(report.cashStart),
            color: AppColors.textPrimary,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Penjualan Tunai Masuk',
            value: _formatCurrency(report.totalSales),
            color: Colors.green[700]!,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Ekspektasi Kas Laci',
            value: _formatCurrency(expectedTotalCash),
            color: AppColors.textPrimary,
            isBold: true,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Kas Riil Laci (Diinput)',
            value: isOpen ? 'Belum Tutup' : _formatCurrency(report.cashEnd),
            color: isOpen ? AppColors.textSecondary : Colors.blue[700]!,
            isBold: !isOpen,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Selisih Uang',
            value: isOpen ? '-' : _formatCurrency(report.cashDifferent),
            color: isOpen
                ? AppColors.textSecondary
                : report.cashDifferent == 0
                    ? Colors.green[700]!
                    : report.cashDifferent > 0
                        ? Colors.teal[800]!
                        : Colors.red[700]!,
            isBold: true,
          ),
          if (!isOpen && report.notes != null && report.notes.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Catatan: ${report.notes}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(dynamic report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performa Shift',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            label: 'Total Omset (Semua Pembayaran)',
            value: _formatCurrency(report.totalSales),
            color: Colors.green[700]!,
            isBold: true,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Total HPP (COGS)',
            value: _formatCurrency(report.totalCogs),
            color: Colors.red[700]!,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Laba Kotor',
            value: _formatCurrency(report.grossProfit),
            color: Colors.teal[800]!,
            isBold: true,
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            label: 'Jumlah Transaksi',
            value: '${report.transactionCount} Transaksi',
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard(dynamic report) {
    final payments = report.paymentBreakdowns;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (payments == null || payments.isEmpty)
            const Text(
              'Belum ada transaksi pembayaran dalam shift ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            )
          else
            ...payments.map<Widget>((breakdown) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.coins,
                        color: Colors.blue[800],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            breakdown.paymentName ?? 'Lainnya',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${breakdown.transactionCount} Transaksi',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(breakdown.totalSales),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.users2,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Riwayat Shift',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
