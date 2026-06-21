import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/shift_provider.dart';

class OpenShiftSheet extends ConsumerStatefulWidget {
  const OpenShiftSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Force them to choose
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const OpenShiftSheet(),
    );
  }

  @override
  ConsumerState<OpenShiftSheet> createState() => _OpenShiftSheetState();
}

class _OpenShiftSheetState extends ConsumerState<OpenShiftSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final cashStart = double.tryParse(_cashController.text) ?? 0.0;
    final activeUser = ref.read(activeUserProvider);
    final userId = activeUser?['id'] as int?;

    final success = await ref.read(shiftProvider.notifier).startNewShift(
      cashStart: cashStart,
      userId: userId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(context, 'Shift berhasil dibuka!');
        Navigator.pop(context);
      } else {
        ToastHelper.showError(context, 'Gagal membuka shift. Silakan coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);
    final cashierName = activeUser?['name'] ?? 'Kasir';

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
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.play,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Buka Shift Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Halo $cashierName, silakan masukkan modal uang tunai awal di laci kasir untuk melacak transaksi shift ini.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Starting cash input
              TextFormField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Uang Modal Awal (Rp) *',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(LucideIcons.banknote, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Modal awal tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  if (double.parse(value) < 0) {
                    return 'Modal awal tidak boleh negatif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes input
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Buka Shift (Opsional)',
                  prefixIcon: Icon(LucideIcons.fileText, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              ToastHelper.showInfo(context, 'Melanjutkan masuk tanpa shift');
                              Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tanpa Shift'),
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
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary,
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
                                'Buka Shift',
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
          ),
        ),
      ),
    );
  }
}
