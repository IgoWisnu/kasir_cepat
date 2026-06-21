import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:kasir_cepat/feature/discount/domain/entities/discount.dart';
import 'package:kasir_cepat/feature/discount/presentation/provider/discount_provider.dart';

class DiscountFormSheet extends ConsumerStatefulWidget {
  final Discount? editingDiscount;

  const DiscountFormSheet({
    super.key,
    this.editingDiscount,
  });

  @override
  ConsumerState<DiscountFormSheet> createState() => _DiscountFormSheetState();
}

class _DiscountFormSheetState extends ConsumerState<DiscountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _valueType = 'percentage'; // 'percentage' or 'fixed'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isSaving = false;

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.editingDiscount != null) {
      final discount = widget.editingDiscount!;
      _nameController.text = discount.name;
      _descController.text = discount.description ?? '';
      _valueController.text = discount.value.toString();
      _valueType = discount.valueType;
      _isActive = discount.isActive;
      _startDate = discount.startDate;
      _endDate = discount.endDate;

      if (_startDate != null) {
        _startDateController.text = _dateFormat.format(_startDate!);
      }
      if (_endDate != null) {
        _endDateController.text = _dateFormat.format(_endDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ToastHelper.showError(context, 'Tanggal selesai tidak boleh sebelum tanggal mulai.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final discount = Discount(
      id: widget.editingDiscount?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      valueType: _valueType,
      value: double.parse(_valueController.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
      createdAt: widget.editingDiscount?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(discountListProvider.notifier).saveDiscountProfile(discount);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingDiscount != null
              ? 'Diskon berhasil diperbarui!'
              : 'Diskon baru berhasil ditambahkan!',
        );
        context.pop();
      } else {
        ToastHelper.showError(context, 'Gagal menyimpan diskon.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.editingDiscount != null ? 'Edit Promo / Diskon' : 'Tambah Promo Baru',
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
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Promo *',
                    hintText: 'Misal: Diskon Ultah, Promo Jumat Berkah',
                    prefixIcon: Icon(LucideIcons.gift, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama promo wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Value Type Selection (percentage vs fixed)
                const Text(
                  'Tipe Nilai Diskon *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ScaleImpactAnimation(
                        onTap: () => setState(() {
                          _valueType = 'percentage';
                          _valueController.clear();
                        }),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _valueType == 'percentage'
                                ? AppColors.primaryLight
                                : Colors.grey[100],
                            border: Border.all(
                              color: _valueType == 'percentage'
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Persentase (%)',
                            style: TextStyle(
                              color: _valueType == 'percentage'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScaleImpactAnimation(
                        onTap: () => setState(() {
                          _valueType = 'fixed';
                          _valueController.clear();
                        }),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _valueType == 'fixed'
                                ? AppColors.primaryLight
                                : Colors.grey[100],
                            border: Border.all(
                              color: _valueType == 'fixed'
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Nominal Tetap (Rp)',
                            style: TextStyle(
                              color: _valueType == 'fixed'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Value Input
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _valueType == 'percentage'
                        ? 'Persentase Diskon (%) *'
                        : 'Nominal Diskon (Rp) *',
                    hintText: _valueType == 'percentage' ? 'Misal: 10 atau 2.5' : 'Misal: 15000',
                    prefixIcon: Icon(
                      _valueType == 'percentage' ? LucideIcons.percent : LucideIcons.banknote,
                      size: 20,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nilai diskon wajib diisi';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (numVal <= 0) {
                      return 'Nilai diskon harus lebih dari 0';
                    }
                    if (_valueType == 'percentage' && numVal > 100) {
                      return 'Persentase diskon tidak boleh melebihi 100%';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date selection row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Mulai',
                          hintText: 'Pilih Tanggal',
                          prefixIcon: const Icon(LucideIcons.calendar, size: 20),
                          suffixIcon: _startDate != null
                              ? ScaleImpactAnimation(
                                  onTap: () {
                                    setState(() {
                                      _startDate = null;
                                      _startDateController.clear();
                                    });
                                  },
                                  child: const Icon(LucideIcons.x, size: 16),
                                )
                              : null,
                        ),
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Selesai',
                          hintText: 'Pilih Tanggal',
                          prefixIcon: const Icon(LucideIcons.calendar, size: 20),
                          suffixIcon: _endDate != null
                              ? ScaleImpactAnimation(
                                  onTap: () {
                                    setState(() {
                                      _endDate = null;
                                      _endDateController.clear();
                                    });
                                  },
                                  child: const Icon(LucideIcons.x, size: 16),
                                )
                              : null,
                        ),
                        onTap: _selectEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description Input
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Tambahkan keterangan promo...',
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Switch Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktifkan Promo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Menentukan apakah promo dapat digunakan di POS',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isActive,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
                    ),
                  ],
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
                            widget.editingDiscount != null ? 'Perbarui Promo' : 'Simpan Promo',
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
      ),
    );
  }
}
