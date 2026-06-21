import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../product/domain/entities/product.dart';
import '../../product/presentation/provider/product_provider.dart';
import 'provider/stock_provider.dart';
import '../domain/usecases/create_opname_batch.dart';

class OpnameBatchPage extends ConsumerStatefulWidget {
  const OpnameBatchPage({super.key});

  @override
  ConsumerState<OpnameBatchPage> createState() => _OpnameBatchPageState();
}

class _OpnameBatchPageState extends ConsumerState<OpnameBatchPage> {
  final _notesController = TextEditingController();

  // Maps product ID to counted physical quantity
  final Map<int, double> _physicalCounts = {};
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'coffee':
        return LucideIcons.coffee;
      case 'sandwich':
        return LucideIcons.sandwich;
      case 'glassWater':
        return LucideIcons.glassWater;
      case 'cake':
        return LucideIcons.cake;
      case 'iceCream':
        return LucideIcons.iceCream;
      case 'apple':
        return LucideIcons.apple;
      case 'shoppingBag':
        return LucideIcons.shoppingBag;
      case 'cookie':
        return LucideIcons.cookie;
      case 'soup':
        return LucideIcons.soup;
      case 'pizza':
        return LucideIcons.pizza;
      case 'gift':
        return LucideIcons.gift;
      case 'shirt':
        return LucideIcons.shirt;
      default:
        return LucideIcons.shoppingBag;
    }
  }

  Future<void> _onSave(List<Product> trackingProducts) async {
    // Collect final maps where physical count was edited (we can pass all reviewed products,
    // since the datasource skips adjustments when offset is 0, but to be clean, we can just pass the ones that were reviewed/initialized)
    final Map<int, double> itemsToSubmit = {};
    for (var product in trackingProducts) {
      final productId = product.id!;
      final physicalVal = _physicalCounts[productId] ?? product.stockQuantity;
      itemsToSubmit[productId] = physicalVal;
    }

    // Count how many products actually have a stock difference
    final adjustedCount = trackingProducts.where((p) {
      final physicalVal = _physicalCounts[p.id!] ?? p.stockQuantity;
      return physicalVal != p.stockQuantity;
    }).length;

    if (adjustedCount == 0) {
      ToastHelper.showError(context, 'Tidak ada selisih stok yang diubah. Opname dibatalkan.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notes = _notesController.text.trim();
    final createOpname = ref.read(createOpnameBatchUseCaseProvider);

    final result = await createOpname(CreateOpnameBatchParams(
      items: itemsToSubmit,
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
        (batchId) {
          ToastHelper.showSuccess(context, 'Batch stock opname berhasil disimpan!');
          ref.read(productListProvider.notifier).loadProducts();
          context.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productListState = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock Opname (Batch)'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          if (!_isSaving)
            productListState.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (products) {
                final trackingProducts = products.where((p) => p.isTrackStock).toList();
                return IconButton(
                  icon: const Icon(LucideIcons.check, color: AppColors.primary),
                  onPressed: trackingProducts.isEmpty ? null : () => _onSave(trackingProducts),
                );
              },
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header Note input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                          const Row(
                            children: [
                              Icon(LucideIcons.clipboardCheck, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Opname',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Stock Opname (Opsional)',
                              hintText: 'Misal: Opname bulanan, Audit berkala',
                              prefixIcon: Icon(LucideIcons.fileText, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Products list
                Expanded(
                  child: productListState.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Center(child: Text('Gagal memuat produk: $err')),
                    data: (products) {
                      final trackingProducts = products.where((p) => p.isTrackStock).toList();

                      if (trackingProducts.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Initialize physical counts map if not done yet
                      if (!_initialized) {
                        for (var p in trackingProducts) {
                          _physicalCounts[p.id!] = p.stockQuantity;
                        }
                        _initialized = true;
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trackingProducts.length,
                        itemBuilder: (context, index) {
                          final product = trackingProducts[index];
                          return _buildOpnameProductCard(product);
                        },
                      );
                    },
                  ),
                ),

                // Bottom Action Bar
                productListState.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (products) {
                    final trackingProducts = products.where((p) => p.isTrackStock).toList();
                    return _buildBottomBar(trackingProducts);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildOpnameProductCard(Product product) {
    final physicalVal = _physicalCounts[product.id] ?? product.stockQuantity;
    final difference = physicalVal - product.stockQuantity;
    final unitAbbrev = product.unitAbbreviation ?? 'pcs';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(product.imagePath),
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Sistem: ${product.stockQuantity.toStringAsFixed(0)} $unitAbbrev',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: difference > 0
                              ? AppColors.success.withValues(alpha: 0.1)
                              : (difference < 0 ? AppColors.error.withValues(alpha: 0.1) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Selisih: ${difference > 0 ? '+' : ''}${difference.toStringAsFixed(0)} $unitAbbrev',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: difference > 0
                                ? AppColors.success
                                : (difference < 0 ? AppColors.error : AppColors.textLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Physical Count Controller
            Row(
              children: [
                ScaleImpactAnimation(
                  onTap: physicalVal > 0
                      ? () {
                          setState(() {
                            _physicalCounts[product.id!] = physicalVal - 1;
                          });
                        }
                      : () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: physicalVal > 0 ? Colors.blue[50] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.minus,
                      size: 16,
                      color: physicalVal > 0 ? Colors.blue : Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text(
                    physicalVal.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleImpactAnimation(
                  onTap: () {
                    setState(() {
                      _physicalCounts[product.id!] = physicalVal + 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<Product> trackingProducts) {
    // Count how many products have differences
    final adjustedCount = trackingProducts.where((p) {
      final physicalVal = _physicalCounts[p.id!] ?? p.stockQuantity;
      return physicalVal != p.stockQuantity;
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: ScaleImpactAnimation(
          onTap: adjustedCount > 0 ? () => _onSave(trackingProducts) : () {},
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: adjustedCount > 0 ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              boxShadow: adjustedCount > 0
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              adjustedCount > 0 ? 'Simpan Opname ($adjustedCount Penyesuaian)' : 'Tidak Ada Selisih Stok',
              style: TextStyle(
                color: adjustedCount > 0 ? Colors.white : Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Tidak ada produk yang dikonfigurasi untuk melacak stok. Silakan aktifkan "Lacak Stok" di profil produk terlebih dahulu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
