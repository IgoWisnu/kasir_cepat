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
import '../domain/usecases/create_restock_batch.dart';

class RestockBatchPage extends ConsumerStatefulWidget {
  const RestockBatchPage({super.key});

  @override
  ConsumerState<RestockBatchPage> createState() => _RestockBatchPageState();
}

class _RestockBatchPageState extends ConsumerState<RestockBatchPage> {
  final _notesController = TextEditingController();
  final _refController = TextEditingController();

  // Maps product ID to restock quantity
  final Map<int, double> _quantities = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _refController.dispose();
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

  Future<void> _onSave() async {
    final filteredItems = Map<int, double>.fromEntries(
      _quantities.entries.where((e) => e.value > 0),
    );

    if (filteredItems.isEmpty) {
      ToastHelper.showError(context, 'Masukkan jumlah restok minimal untuk 1 barang');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notes = _notesController.text.trim();
    final reference = _refController.text.trim();
    final createRestock = ref.read(createRestockBatchUseCaseProvider);

    final result = await createRestock(CreateRestockBatchParams(
      items: filteredItems,
      notes: notes.isEmpty ? null : notes,
      reference: reference.isEmpty ? null : reference,
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
          ToastHelper.showSuccess(context, 'Batch restok berhasil disimpan!');
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
        title: const Text('Restok Barang (Batch)'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(LucideIcons.check, color: AppColors.primary),
              onPressed: _onSave,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header Inputs Card
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
                              Icon(LucideIcons.fileText, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Batch Restok',
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
                            controller: _refController,
                            decoration: const InputDecoration(
                              labelText: 'No. Referensi / Invoice (Opsional)',
                              hintText: 'Misal: INV/2026/001',
                              prefixIcon: Icon(LucideIcons.hash, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Restok (Opsional)',
                              hintText: 'Misal: Pengiriman dari Supplier A',
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

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trackingProducts.length,
                        itemBuilder: (context, index) {
                          final product = trackingProducts[index];
                          return _buildRestockProductCard(product);
                        },
                      );
                    },
                  ),
                ),

                // Bottom Action Bar
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildRestockProductCard(Product product) {
    final qty = _quantities[product.id] ?? 0.0;
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
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(product.imagePath),
                color: AppColors.primary,
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
                  Text(
                    'Stok saat ini: ${product.stockQuantity.toStringAsFixed(0)} $unitAbbrev',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Counter Controller
            Row(
              children: [
                ScaleImpactAnimation(
                  onTap: qty > 0
                      ? () {
                          setState(() {
                            _quantities[product.id!] = qty - 1;
                          });
                        }
                      : () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppColors.primaryLight : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.minus,
                      size: 16,
                      color: qty > 0 ? AppColors.primary : Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text(
                    qty.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: qty > 0 ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleImpactAnimation(
                  onTap: () {
                    setState(() {
                      _quantities[product.id!] = qty + 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: AppColors.primary,
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

  Widget _buildBottomBar() {
    final activeItemCount = _quantities.values.where((v) => v > 0).length;

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
          onTap: activeItemCount > 0 ? _onSave : () {},
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: activeItemCount > 0 ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              boxShadow: activeItemCount > 0
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
              activeItemCount > 0 ? 'Simpan Restok ($activeItemCount Barang)' : 'Pilih Barang untuk Direstok',
              style: TextStyle(
                color: activeItemCount > 0 ? Colors.white : Colors.grey[500],
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
