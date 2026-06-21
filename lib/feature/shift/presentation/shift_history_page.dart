import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/shift.dart';
import 'provider/shift_provider.dart';

final shiftsListProvider = FutureProvider.autoDispose<List<Shift>>((ref) async {
  final getShifts = ref.read(getShiftsUseCaseProvider);
  final result = await getShifts(NoParams());
  return result.fold(
    (failure) => throw failure.message,
    (shifts) => shifts,
  );
});

final usersMapProvider = FutureProvider.autoDispose<Map<int, String>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final results = await db.query('users');
  final map = <int, String>{};
  for (final row in results) {
    final id = row['id'] as int;
    final name = row['name'] as String;
    map[id] = name;
  }
  return map;
});

class ShiftHistoryPage extends ConsumerWidget {
  const ShiftHistoryPage({super.key});

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsState = ref.watch(shiftsListProvider);
    final usersState = ref.watch(usersMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Shift Kasir',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shiftsListProvider);
            ref.invalidate(usersMapProvider);
          },
          child: shiftsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat riwayat: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(shiftsListProvider);
                        ref.invalidate(usersMapProvider);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (shifts) {
              if (shifts.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.clock, size: 48, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum Ada Riwayat Shift',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Semua riwayat pembukaan dan penutupan shift kasir akan ditampilkan di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  final isClosed = shift.status == ShiftStatus.closed;
                  
                  // For closed shifts, cashSales = cashEnd - cashStart - cashDifferent
                  // for open shifts, load dynamically
                  final double? cashSales = isClosed
                      ? (shift.cashEnd ?? 0.0) - shift.cashStart - (shift.cashDifferent ?? 0.0)
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (ID & Status)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shift #${shift.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isClosed ? Colors.grey[100] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isClosed ? Colors.grey[300]! : Colors.green[200]!,
                                  ),
                                ),
                                child: Text(
                                  isClosed ? 'Selesai' : 'Aktif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isClosed ? Colors.grey[700] : Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Details
                          _buildRecapRow(
                            'Kasir',
                            usersState.maybeWhen(
                              data: (users) => users[shift.userId] ?? 'Kasir #${shift.userId}',
                              orElse: () => 'Memuat...',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRecapRow(
                            'Waktu Mulai',
                            _formatDateTime(shift.startTime),
                          ),
                          if (isClosed && shift.endTime != null) ...[
                            const SizedBox(height: 8),
                            _buildRecapRow(
                              'Waktu Selesai',
                              _formatDateTime(shift.endTime!),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Cash Stats
                          _buildRecapRow(
                            'Modal Awal',
                            _formatCurrency(shift.cashStart),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Penjualan Tunai',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              if (isClosed)
                                Text(
                                  _formatCurrency(cashSales ?? 0.0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              else
                                OpenShiftSalesText(shiftId: shift.id!),
                            ],
                          ),
                          
                          if (isClosed) ...[
                            const SizedBox(height: 8),
                            _buildRecapRow(
                              'Uang Aktual',
                              _formatCurrency(shift.cashEnd ?? 0.0),
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Selisih Kas',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                _buildDifferentText(shift.cashDifferent ?? 0.0),
                              ],
                            ),
                          ],
                          
                          // Notes
                          if (shift.notes != null && shift.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.fileText,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      shift.notes!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecapRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDifferentText(double diff) {
    final text = diff == 0.0
        ? 'Sesuai'
        : diff > 0.0
            ? 'Kelebihan (+ ${_formatCurrency(diff)})'
            : 'Kurang (${_formatCurrency(diff)})';

    final color = diff == 0.0
        ? AppColors.textPrimary
        : diff > 0.0
            ? Colors.green[800]
            : Colors.red[800];

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

class OpenShiftSalesText extends ConsumerWidget {
  final int shiftId;
  const OpenShiftSalesText({super.key, required this.shiftId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<double>(
      future: ref.read(getShiftCashSalesUseCaseProvider)(shiftId).then((res) => res.fold((_) => 0.0, (val) => val)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textPrimary),
          );
        }
        final sales = snapshot.data ?? 0.0;
        return Text(
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(sales),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        );
      },
    );
  }
}
