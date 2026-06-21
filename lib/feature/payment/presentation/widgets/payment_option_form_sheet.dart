import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../domain/entities/payment_option.dart';
import '../provider/payment_option_provider.dart';

class PaymentOptionFormSheet extends ConsumerStatefulWidget {
  final PaymentOption? editingOption;

  const PaymentOptionFormSheet({
    super.key,
    this.editingOption,
  });

  @override
  ConsumerState<PaymentOptionFormSheet> createState() => _PaymentOptionFormSheetState();
}

class _PaymentOptionFormSheetState extends ConsumerState<PaymentOptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  late PaymentOptionType _selectedType;
  late String _selectedIcon;
  late bool _isActive;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _availableIcons = [
    {'key': 'banknote', 'icon': LucideIcons.banknote, 'label': 'Tunai'},
    {'key': 'qr_code', 'icon': LucideIcons.qrCode, 'label': 'QR Code'},
    {'key': 'credit_card', 'icon': LucideIcons.creditCard, 'label': 'Kartu'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingOption != null) {
      _nameController.text = widget.editingOption!.name;
      _descController.text = widget.editingOption!.description ?? '';
      _selectedType = widget.editingOption!.type;
      _selectedIcon = widget.editingOption!.icon ?? 'banknote';
      _isActive = widget.editingOption!.status == PaymentOptionStatus.active;
    } else {
      _selectedType = PaymentOptionType.cash;
      _selectedIcon = 'banknote';
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final option = PaymentOption(
      id: widget.editingOption?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      icon: _selectedIcon,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      status: _isActive ? PaymentOptionStatus.active : PaymentOptionStatus.inactive,
      createdAt: widget.editingOption?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(paymentOptionListProvider.notifier).saveOption(option);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingOption != null
              ? 'Metode pembayaran berhasil diperbarui!'
              : 'Metode pembayaran baru berhasil ditambahkan!',
        );
        context.pop();
      } else {
        ToastHelper.showError(
          context,
          'Gagal menyimpan metode pembayaran. Nama mungkin sudah terdaftar.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standard bottom sheet padding to account for keyboard popup overlay
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle / Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editingOption != null ? 'Edit Metode Pembayaran' : 'Tambah Metode Pembayaran',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  ScaleImpactAnimation(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),

              // Name Input
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Metode Pembayaran *',
                  hintText: 'Misal: ShopeePay, Bank Mandiri, Tunai',
                  prefixIcon: Icon(LucideIcons.creditCard, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama metode pembayaran wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<PaymentOptionType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Pembayaran *',
                  prefixIcon: Icon(LucideIcons.wallet, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PaymentOptionType.cash,
                    child: Text('Tunai'),
                  ),
                  DropdownMenuItem(
                    value: PaymentOptionType.nonCash,
                    child: Text('Non-Tunai'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Visual Icon Picker
              Text(
                'Pilih Ikon Metode Pembayaran *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _availableIcons.map((iconMap) {
                  final key = iconMap['key'] as String;
                  final iconData = iconMap['icon'] as IconData;
                  final label = iconMap['label'] as String;
                  final isSelected = _selectedIcon == key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: ScaleImpactAnimation(
                      onTap: () {
                        setState(() {
                          _selectedIcon = key;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryDark : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Description Input
              TextFormField(
                controller: _descController,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  hintText: 'Misal: Pembayaran menggunakan QRIS DANA/OVO/GoPay',
                  prefixIcon: Icon(LucideIcons.fileText, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Status Switch
              SwitchListTile(
                title: const Text(
                  'Status Aktif',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _isActive
                      ? 'Metode pembayaran aktif dan bisa digunakan saat checkout.'
                      : 'Metode pembayaran dinonaktifkan.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save Button
              ScaleImpactAnimation(
                onTap: _isSaving ? () {} : _onSave,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.editingOption != null ? 'Perbarui Metode' : 'Simpan Metode',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
