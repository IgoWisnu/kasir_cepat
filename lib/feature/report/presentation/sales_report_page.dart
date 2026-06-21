import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import 'provider/report_provider.dart';

class SalesReportPage extends ConsumerStatefulWidget {
  const SalesReportPage({super.key});

  @override
  ConsumerState<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends ConsumerState<SalesReportPage> {
  String _selectedDateFilter = 'hari_ini'; // 'hari_ini', 'kemarin', '7_hari', '30_hari', 'kustom'

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  void _setDateRange(String val) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange newRange;

    switch (val) {
      case 'hari_ini':
        newRange = DateTimeRange(
          start: today,
          end: today.add(const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        );
        break;
      case 'kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        newRange = DateTimeRange(
          start: yesterday,
          end: yesterday.add(const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        );
        break;
      case '7_hari':
        newRange = DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case '30_hari':
        newRange = DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case 'kustom':
        final currentRange = ref.read(salesReportDateRangeProvider);
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: currentRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          final adjustedRange = DateTimeRange(
            start: DateTime(range.start.year, range.start.month, range.start.day),
            end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999),
          );
          ref.read(salesReportDateRangeProvider.notifier).state = adjustedRange;
          setState(() {
            _selectedDateFilter = 'kustom';
          });
        }
        return;
      default:
        return;
    }

    ref.read(salesReportDateRangeProvider.notifier).state = newRange;
    setState(() {
      _selectedDateFilter = val;
    });
  }

  String _getDateFilterLabel(DateTimeRange range) {
    if (_selectedDateFilter == 'kustom') {
      final start = DateFormat('dd/MM/yyyy').format(range.start);
      final end = DateFormat('dd/MM/yyyy').format(range.end);
      return '$start - $end';
    }
    switch (_selectedDateFilter) {
      case 'hari_ini': return 'Hari Ini';
      case 'kemarin': return 'Kemarin';
      case '7_hari': return '7 Hari Terakhir';
      case '30_hari': return '30 Hari Terakhir';
      default: return 'Hari Ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(salesReportDateRangeProvider);
    final reportAsync = ref.watch(salesReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Penjualan',
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
      body: Column(
        children: [
          // Filter Bar
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
                const Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDateFilterLabel(dateRange),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildFilterDropdown(),
              ],
            ),
          ),

          // Report Content
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Gagal memuat laporan: $err', textAlign: TextAlign.center),
                ),
              ),
              data: (report) {
                if (report.totalSales == 0) {
                  return _buildEmptyState();
                }

                final marginPercent = report.totalSales > 0
                    ? (report.grossProfit / report.totalSales) * 100
                    : 0.0;

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.refresh(salesReportProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Overview cards
                      _buildSummaryCard(report, marginPercent),
                      const SizedBox(height: 24),

                      // Category breakdowns
                      _buildCategoryBreakdowns(report),
                      const SizedBox(height: 24),

                      // Payment breakdowns
                      _buildPaymentBreakdowns(report),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDateFilter,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'hari_ini', child: Text('Hari Ini')),
            DropdownMenuItem(value: 'kemarin', child: Text('Kemarin')),
            DropdownMenuItem(value: '7_hari', child: Text('7 Hari')),
            DropdownMenuItem(value: '30_hari', child: Text('30 Hari')),
            DropdownMenuItem(value: 'kustom', child: Text('Kustom...')),
          ],
          onChanged: (val) {
            if (val != null) {
              _setDateRange(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(dynamic report, double marginPercent) {
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
            'Ikhtisar Keuangan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            label: 'Total Penjualan (Omset)',
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
            label: 'Total Diskon',
            value: _formatCurrency(report.totalDiscounts),
            color: Colors.purple[700]!,
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
            label: 'Margin Profit',
            value: '${marginPercent.toStringAsFixed(1)}%',
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

  Widget _buildCategoryBreakdowns(dynamic report) {
    final categories = report.categoryBreakdowns;

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
            'Penjualan per Kategori',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (categories == null || categories.isEmpty)
            const Text(
              'Tidak ada data penjualan per kategori.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            )
          else
            ...categories.map<Widget>((breakdown) {
              final catPercent = report.totalSales > 0
                  ? (breakdown.totalSales / report.totalSales)
                  : 0.0;
              final catPercentLabel = (catPercent * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          breakdown.categoryName ?? 'Tanpa Kategori',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${breakdown.quantitySold.toStringAsFixed(0)} pcs / ${_formatCurrency(breakdown.totalSales)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: catPercent.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.teal[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$catPercentLabel% dari total omset',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdowns(dynamic report) {
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
            'Metode Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (payments == null || payments.isEmpty)
            const Text(
              'Tidak ada data pembayaran.',
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
                        LucideIcons.creditCard,
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

  Widget _buildEmptyState() {
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
                  LucideIcons.barChart3,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Data Penjualan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum terdeteksi adanya transaksi yang selesai (completed) pada rentang tanggal yang dipilih.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
