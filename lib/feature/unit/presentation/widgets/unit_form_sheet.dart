import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:kasir_cepat/feature/unit/domain/entities/unit_entity.dart';
import 'package:kasir_cepat/feature/unit/presentation/provider/unit_provider.dart';

class UnitFormSheet extends ConsumerStatefulWidget {
  final Unit? editingUnit;

  const UnitFormSheet({
    super.key,
    this.editingUnit,
  });

  @override
  ConsumerState<UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends ConsumerState<UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _abbrevController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingUnit != null) {
      _nameController.text = widget.editingUnit!.name;
      _abbrevController.text = widget.editingUnit!.abbreviation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrevController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final unit = Unit(
      id: widget.editingUnit?.id,
      name: _nameController.text.trim(),
      abbreviation: _abbrevController.text.trim(),
      createdAt: widget.editingUnit?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(unitListProvider.notifier).saveUnitProfile(unit);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingUnit != null
              ? 'Satuan berhasil diperbarui!'
              : 'Satuan baru berhasil ditambahkan!',
        );
        context.pop();
      } else {
        ToastHelper.showError(
          context,
          'Gagal menyimpan satuan. Nama satuan mungkin sudah terdaftar.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standard bottom sheet padding to account for keyboard popup overlay
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
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
                  widget.editingUnit != null ? 'Edit Satuan' : 'Tambah Satuan Baru',
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
                labelText: 'Nama Satuan *',
                hintText: 'Misal: Kilogram, Pieces, Box',
                prefixIcon: Icon(LucideIcons.layers, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama satuan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Abbreviation Input
            TextFormField(
              controller: _abbrevController,
              decoration: const InputDecoration(
                labelText: 'Singkatan / Simbol *',
                hintText: 'Misal: kg, pcs, box',
                prefixIcon: Icon(LucideIcons.hash, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Singkatan wajib diisi';
                }
                return null;
              },
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
                        widget.editingUnit != null ? 'Perbarui Satuan' : 'Simpan Satuan',
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
    );
  }
}
