import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/shift_provider.dart';

class EndShiftSheet extends ConsumerStatefulWidget {
  const EndShiftSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const EndShiftSheet(),
    );
  }

  @override
  ConsumerState<EndShiftSheet> createState() => _EndShiftSheetState();
}

class _EndShiftSheetState extends ConsumerState<EndShiftSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cashEndController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoadingSales = true;
  bool _isSubmitting = false;
  double _cashSales = 0.0;
  double _expectedTotal = 0.0;
  double _cashEnd = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  @override
  void dispose() {
    _cashEndController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesData() async {
    final activeShift = ref.read(shiftProvider).value;
    if (activeShift != null) {
      final getCashSales = ref.read(getShiftCashSalesUseCaseProvider);
      final result = await getCashSales(activeShift.id!);
      result.fold(
        (failure) {
          if (mounted) {
            ToastHelper.showError(context, 'Gagal memuat omzet tunai: ${failure.message}');
            setState(() {
              _isLoadingSales = false;
            });
          }
        },
        (sales) {
          if (mounted) {
            setState(() {
              _cashSales = sales;
              _expectedTotal = activeShift.cashStart + sales;
              _isLoadingSales = false;
            });
          }
        },
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoadingSales = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final activeShift = ref.read(shiftProvider).value;
    if (activeShift == null) {
      ToastHelper.showError(context, 'Tidak ada shift aktif yang ditemukan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await ref.read(shiftProvider.notifier).closeActiveShift(
      shiftId: activeShift.id!,
      cashEnd: _cashEnd,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(context, 'Shift berhasil diakhiri!');
        Navigator.pop(context); // Close sheet
      } else {
        ToastHelper.showError(context, 'Gagal mengakhiri shift. Silakan coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShift = ref.watch(shiftProvider).value;
    final activeUser = ref.watch(activeUserProvider);
    final cashierName = activeUser?['name'] ?? 'Kasir';

    if (activeShift == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              'Tidak Ada Shift Aktif',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final diff = _cashEnd - _expectedTotal;
    final formattedStartTime = DateFormat('dd MMM yyyy, HH:mm').format(activeShift.startTime);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.stopCircle,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Akhiri Shift Kasir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingSales)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...[
                // Shift Details Table/Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Kasir', cashierName),
                      const Divider(height: 20),
                      _buildDetailRow('Waktu Mulai', formattedStartTime),
                      const Divider(height: 20),
                      _buildDetailRow('Modal Awal tunai', _formatCurrency(activeShift.cashStart)),
                      const Divider(height: 20),
                      _buildDetailRow('Penjualan Tunai Shift', _formatCurrency(_cashSales)),
                      const Divider(height: 20),
                      _buildDetailRow(
                        'Ekspektasi Uang di Laci',
                        _formatCurrency(_expectedTotal),
                        isBoldValue: true,
                        valueColor: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cash End Input
                TextFormField(
                  controller: _cashEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang Tunai Aktual di Laci (Rp) *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(LucideIcons.banknote, size: 20),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _cashEnd = double.tryParse(val) ?? 0.0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Uang aktual laci tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (double.parse(value) < 0) {
                      return 'Uang aktual laci tidak boleh negatif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Live difference display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: diff == 0
                        ? Colors.grey[100]
                        : diff > 0
                            ? Colors.green[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selisih Kas:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        diff == 0
                            ? 'Sesuai'
                            : diff > 0
                                ? 'Kelebihan (+ ${_formatCurrency(diff)})'
                                : 'Kurang (${_formatCurrency(diff)})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: diff == 0
                              ? AppColors.textPrimary
                              : diff > 0
                                  ? Colors.green[800]
                                  : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Input
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Tutup Shift (Opsional)',
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScaleImpactAnimation(
                        onTap: () {
                          if (!_isSubmitting) {
                            _submit();
                          }
                        },
                        child: ElevatedButton(
                          onPressed: null, // Managed by ScaleImpactAnimation
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Akhiri Shift',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
