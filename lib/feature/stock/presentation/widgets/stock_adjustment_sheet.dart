import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../product/domain/entities/product.dart';
import '../provider/stock_provider.dart';
import '../../../product/presentation/provider/product_provider.dart';
import '../../domain/usecases/adjust_stock.dart';

class StockAdjustmentBottomSheet extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustmentBottomSheet({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<StockAdjustmentBottomSheet> createState() => _StockAdjustmentBottomSheetState();
}

class _StockAdjustmentBottomSheetState extends ConsumerState<StockAdjustmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _difference = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default physical count to current stock
    _quantityController.text = widget.product.stockQuantity.toStringAsFixed(0);
    _quantityController.addListener(_calculateDifference);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateDifference);
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateDifference() {
    final inputVal = double.tryParse(_quantityController.text.trim());
    if (inputVal != null) {
      setState(() {
        _difference = inputVal - widget.product.stockQuantity;
      });
    } else {
      setState(() {
        _difference = 0.0;
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newQty = double.tryParse(_quantityController.text.trim());
    if (newQty == null) return;

    setState(() {
      _isSaving = true;
    });

    final notes = _notesController.text.trim();
    final adjustStock = ref.read(adjustStockUseCaseProvider);

    final result = await adjustStock(AdjustStockParams(
      productId: widget.product.id!,
      newQuantity: newQty,
      notes: notes.isEmpty ? null : notes,
    ));

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      result.fold(
        (failure) {
          ToastHelper.showError(context, failure.message);
        },
        (_) {
          ToastHelper.showSuccess(context, 'Stok berhasil disesuaikan!');
          // Refresh product list to reflect changes reactively
          ref.read(productListProvider.notifier).loadProducts();
          context.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final unitAbbrev = widget.product.unitAbbreviation ?? 'pcs';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sesuaikan Stok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ScaleImpactAnimation(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            // Stock Details and Offset Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Stok Sistem',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.stockQuantity.toStringAsFixed(0)} $unitAbbrev',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: AppColors.border),
                  Column(
                    children: [
                      const Text(
                        'Selisih Penyesuaian',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _difference > 0
                                ? LucideIcons.plusCircle
                                : (_difference < 0 ? LucideIcons.minusCircle : LucideIcons.checkCircle),
                            size: 14,
                            color: _difference > 0
                                ? AppColors.success
                                : (_difference < 0 ? AppColors.error : AppColors.textLight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_difference > 0 ? '+' : ''}${_difference.toStringAsFixed(0)} $unitAbbrev',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _difference > 0
                                  ? AppColors.success
                                  : (_difference < 0 ? AppColors.error : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actual Physical Count Input
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok Fisik Baru *',
                hintText: '0',
                prefixIcon: const Icon(LucideIcons.package, size: 20),
                suffixText: unitAbbrev,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Jumlah stok fisik wajib diisi';
                }
                final numVal = double.tryParse(val.trim());
                if (numVal == null) {
                  return 'Masukkan format angka yang valid';
                }
                if (numVal < 0) {
                  return 'Jumlah stok tidak boleh kurang dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes Input
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Catatan Penyesuaian (Opsional)',
                hintText: 'Contoh: Stok pecah/rusak, Hasil stock take',
                prefixIcon: Icon(LucideIcons.fileText, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
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
                    : const Text(
                        'Simpan Penyesuaian',
                        style: TextStyle(
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
