import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../domain/entities/product.dart';
import 'provider/product_provider.dart';
import '../../categories/presentation/provider/category_provider.dart';
import 'widgets/product_thumbnail.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _onDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus produk "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(productListProvider.notifier).deleteProductProfile(product.id!);
      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Produk berhasil dihapus!');
        } else {
          ToastHelper.showError(context, 'Gagal menghapus produk.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productListState = ref.watch(productListProvider);
    final categoryListState = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama, SKU, atau barcode produk...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? ScaleImpactAnimation(
                        onTap: () => _searchController.clear(),
                        child: const Icon(LucideIcons.x, size: 18),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 2. Horizontal Category Filter
          categoryListState.when(
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox(height: 50),
            data: (categories) {
              return Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categories[index - 1];
                    final categoryId = category?.id;
                    final isSelected = _selectedCategoryId == categoryId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: ScaleImpactAnimation(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = categoryId;
                          });
                          // Re-fetch products filtered by category from database
                          ref.read(productListProvider.notifier).loadProducts(categoryId: categoryId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAll ? 'Semua' : category!.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 3. Product List
          Expanded(
            child: productListState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Terjadi Kesalahan: $err')),
              data: (products) {
                // Apply search filter locally
                final filteredProducts = products.where((product) {
                  final matchesName = product.name.toLowerCase().contains(_searchQuery);
                  final matchesSku = product.sku?.toLowerCase().contains(_searchQuery) ?? false;
                  final matchesBarcode = product.barcode?.toLowerCase().contains(_searchQuery) ?? false;
                  final matchesDesc = product.description?.toLowerCase().contains(_searchQuery) ?? false;
                  return matchesName || matchesSku || matchesBarcode || matchesDesc;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleImpactAnimation(
        onTap: () => context.push('/products/form'),
        child: FloatingActionButton(
          onPressed: null, // Let ScaleImpactAnimation handle click
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isStockLow = product.isTrackStock && product.stockQuantity <= 5;
    final isOutOfStock = product.isTrackStock && product.stockQuantity <= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon / Image Placeholder
            ProductThumbnail(
              imagePath: product.imagePath,
              size: 56,
              iconSize: 26,
              color: product.status == ProductStatus.available
                  ? AppColors.primaryLight
                  : Colors.grey[200],
              iconColor: product.status == ProductStatus.available
                  ? AppColors.primary
                  : AppColors.textLight,
            ),
            const SizedBox(width: 12),

            // Middle Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Category tag
                  if (product.categoryName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Price
                  Text(
                    _formatCurrency(product.sellingPrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  // Cost Price (optional)
                  if (product.costPrice != null) ...[
                    Text(
                      'Beli: ${_formatCurrency(product.costPrice!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Stock indicator
                  Row(
                    children: [
                      Icon(
                        product.isTrackStock ? LucideIcons.layers : LucideIcons.helpCircle,
                        size: 13,
                        color: isOutOfStock
                            ? AppColors.primary
                            : (isStockLow ? AppColors.warning : AppColors.textLight),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.isTrackStock
                            ? 'Stok: ${product.stockQuantity.toStringAsFixed(0)} ${product.unitAbbreviation ?? 'pcs'}'
                            : 'Stok: Tidak dilacak',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: product.isTrackStock ? FontWeight.w600 : FontWeight.normal,
                          color: isOutOfStock
                              ? AppColors.primary
                              : (isStockLow ? AppColors.warning : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Status / Actions Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Available / Unavailable badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.status == ProductStatus.available
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.status == ProductStatus.available ? 'Tersedia' : 'Non-aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: product.status == ProductStatus.available
                          ? AppColors.success
                          : AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Edit & Delete Actions
                Row(
                  children: [
                    ScaleImpactAnimation(
                      onTap: () => context.push('/products/form', extra: product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(LucideIcons.edit2, size: 16, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ScaleImpactAnimation(
                      onTap: () => _onDeleteProduct(product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(LucideIcons.trash2, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.package,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tekan tombol + di kanan bawah untuk menambahkan produk baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
