import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:kasir_cepat/feature/categories/domain/entities/category.dart';
import 'package:kasir_cepat/feature/categories/presentation/provider/category_provider.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? editingCategory;

  const CategoryFormSheet({
    super.key,
    this.editingCategory,
  });

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingCategory != null) {
      _nameController.text = widget.editingCategory!.name;
      _descController.text = widget.editingCategory!.description ?? '';
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

    final category = Category(
      id: widget.editingCategory?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      createdAt: widget.editingCategory?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(categoryListProvider.notifier).saveCategoryProfile(category);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingCategory != null
              ? 'Kategori berhasil diperbarui!'
              : 'Kategori baru berhasil ditambahkan!',
        );
        context.pop();
      } else {
        ToastHelper.showError(
          context,
          'Gagal menyimpan kategori. Nama kategori mungkin sudah terdaftar.',
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
                  widget.editingCategory != null ? 'Edit Kategori' : 'Tambah Kategori Baru',
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
                labelText: 'Nama Kategori *',
                hintText: 'Misal: Makanan, Minuman, Lainnya',
                prefixIcon: Icon(LucideIcons.tag, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama kategori wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descController,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Misal: Berbagai jenis minuman dingin dan hangat',
                prefixIcon: Icon(LucideIcons.fileText, size: 20),
              ),
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
                        widget.editingCategory != null ? 'Perbarui Kategori' : 'Simpan Kategori',
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
