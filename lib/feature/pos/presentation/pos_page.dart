import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../product/domain/entities/product.dart';
import '../../product/presentation/provider/product_provider.dart';
import '../../categories/presentation/provider/category_provider.dart';
import '../../order/domain/entities/order.dart';
import '../../order/domain/entities/order_item.dart';
import '../../order/presentation/provider/order_provider.dart';
import 'provider/cart_provider.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../../shift/presentation/provider/shift_provider.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _orderNotesController = TextEditingController();
  
  String _searchQuery = '';
  int? _selectedCategoryId;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    // Sync controllers with current cart state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = ref.read(cartProvider);
      _customerNameController.text = cart.customerName;
      _orderNotesController.text = cart.notes;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  void _showPendingOrdersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _PendingOrdersSheet(),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CartDetailSheet(
          customerNameController: _customerNameController,
          orderNotesController: _orderNotesController,
        );
      },
    );
  }

  Future<void> _onSavePendingOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ToastHelper.showError(context, 'Keranjang belanja kosong');
      return;
    }

    // Save pending order
    final orderItems = cart.items.map((item) {
      return OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        priceAtPurchase: item.product.sellingPrice,
        costPrice: item.product.costPrice ?? 0.0,
        qty: item.quantity,
        discountValue: item.discountValue,
        subtotal: item.subtotal,
        createdAt: DateTime.now(),
      );
    }).toList();

    final activeUser = ref.read(activeUserProvider);
    final activeShift = ref.read(shiftProvider).value;

    final order = Order(
      id: cart.editingOrderId,
      orderQueue: cart.orderQueue ?? 0, // Computed in DB for new, preserved for edits
      invoiceNumber: cart.invoiceNumber,
      customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
      orderType: cart.orderType,
      orderStatus: OrderStatus.newOrder,
      paymentStatus: PaymentStatus.pending,
      subtotal: cart.subtotal,
      grandTotal: cart.grandTotal,
      notes: _orderNotesController.text.trim().isEmpty ? null : _orderNotesController.text.trim(),
      userId: activeUser?['id'] as int?,
      shiftId: activeShift?.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: orderItems,
    );

    bool success = false;
    if (cart.editingOrderId != null) {
      success = await ref.read(orderListProvider.notifier).updateOrderDetails(order);
    } else {
      final orderId = await ref.read(orderListProvider.notifier).createOrder(order);
      success = orderId != null;
    }

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          cart.editingOrderId != null
              ? 'Pesanan tertunda berhasil diperbarui!'
              : 'Pesanan tertunda berhasil disimpan!',
        );
        ref.read(cartProvider.notifier).clearCart();
        _customerNameController.clear();
        _orderNotesController.clear();
      } else {
        ToastHelper.showError(context, 'Gagal menyimpan pesanan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final categoryState = ref.watch(categoryListProvider);
    final cart = ref.watch(cartProvider);

    // Filter products locally by category & search query
    List<Product> filteredProducts = [];
    productState.whenData((products) {
      filteredProducts = products.where((product) {
        final matchesCategory = _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
            (product.sku?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POS Penjualan'),
            if (cart.editingOrderId != null)
              Text(
                'Mengedit Pesanan #${cart.orderQueue}',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        leading: ScaleImpactAnimation(
          onTap: () {
            if (cart.items.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tinggalkan POS?'),
                  content: const Text('Keranjang belanja Anda saat ini akan hilang.'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        context.pop(); // Close dialog
                        if (context.canPop()) {
                          context.pop(); // Go back
                        } else {
                          context.go('/'); // Go to dashboard
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          // Active Pending Orders loader trigger
          ScaleImpactAnimation(
            onTap: _showPendingOrdersSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  ref.watch(orderListProvider).maybeWhen(
                    data: (orders) {
                      final pendingCount = orders.where((o) => o.paymentStatus == PaymentStatus.pending).length;
                      return Text(
                        '$pendingCount Aktif',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      );
                    },
                    orElse: () => const Text('0 Aktif', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Category Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk berdasarkan nama, barcode, SKU...',
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

          // Horizontal Category List
          SizedBox(
            height: 48,
            child: categoryState.when(
              loading: () => const SizedBox(),
              error: (err, _) => const SizedBox(),
              data: (categories) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final cat = isAll ? null : categories[index - 1];
                    final catId = isAll ? null : cat?.id;
                    final catName = isAll ? 'Semua' : cat?.name ?? '';
                    final isSelected = _selectedCategoryId == catId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ScaleImpactAnimation(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = catId;
                          });
                        },
                        child: ChoiceChip(
                          label: Text(catName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = catId;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          elevation: 1,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryDark : AppColors.border,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Product Catalog Grid
          Expanded(
            child: productState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Gagal memuat katalog: $err')),
              data: (_) {
                if (filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product, cart);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Sticky Bottom Cart Bar
      bottomSheet: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.items.fold(0.0, (sum, i) => sum + i.quantity).toStringAsFixed(0)} Barang',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(cart.grandTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save Pending Order Button
                      ScaleImpactAnimation(
                        onTap: _onSavePendingOrder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(LucideIcons.save, color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Checkout Button
                      ScaleImpactAnimation(
                        onTap: _showCartSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Keranjang',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(width: 8),
                              Icon(LucideIcons.shoppingBag, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildProductCard(Product product, CartState cart) {
    // Get quantity of this product in cart
    final cartIdx = cart.items.indexWhere((item) => item.product.id == product.id);
    final cartQty = cartIdx != -1 ? cart.items[cartIdx].quantity : 0.0;
    
    final isTrackStock = product.isTrackStock;
    final stockVal = product.stockQuantity;
    final isOutOfStock = isTrackStock && stockVal <= 0;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cartQty > 0 ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent, width: 1.5),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dummy visual thumbnail (Red Tint Badge matching Kasir Cepat)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.package,
                  color: isOutOfStock ? AppColors.textLight : AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Product name
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),

            // Product Price
            Text(
              _currencyFormat.format(product.sellingPrice),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 6),

            // Stock Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTrackStock ? 'Stok: ${stockVal.toStringAsFixed(0)}' : 'Stok: ∞',
                  style: TextStyle(fontSize: 11, color: isOutOfStock ? Colors.red : AppColors.textSecondary),
                ),
                if (isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
                    child: const Text(
                      'Habis',
                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Cart Adjustments or Add Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: isOutOfStock
                  ? Container(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('Stok Habis', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    )
                  : cartQty > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ScaleImpactAnimation(
                              onTap: () {
                                ref.read(cartProvider.notifier).updateQuantity(product.id!, cartQty - 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.minus, size: 16, color: AppColors.primary),
                              ),
                            ),
                            Text(
                              cartQty.toStringAsFixed(0),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            ScaleImpactAnimation(
                              onTap: () {
                                if (isTrackStock && cartQty >= stockVal) {
                                  ToastHelper.showWarning(context, 'Stok maksimum tercapai');
                                  return;
                                }
                                ref.read(cartProvider.notifier).addItem(product);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : ScaleImpactAnimation(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(product);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Tambah',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(LucideIcons.search, color: AppColors.textLight, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Produk Tidak Ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba ganti kata kunci atau pilih kategori lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingOrdersSheet extends ConsumerWidget {
  const _PendingOrdersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);
    final productState = ref.watch(productListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Antrean / Pesanan Aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => context.pop(),
                  )
                ],
              ),
              const Divider(color: AppColors.border),
              Expanded(
                child: orderState.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Center(child: Text('Gagal memuat: $err')),
                  data: (orders) {
                    final pendingOrders = orders.where((o) => o.paymentStatus == PaymentStatus.pending).toList();

                    if (pendingOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.inbox, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('Tidak ada antrean pesanan aktif', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: pendingOrders.length,
                      itemBuilder: (context, index) {
                        final order = pendingOrders[index];
                        final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.clock, color: AppColors.primary),
                            ),
                            title: Text(
                              'Pesanan #${order.orderQueue} ${order.customerName != null ? "(${order.customerName})" : ""}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${order.orderType == OrderType.dineIn ? "Dine-in" : order.orderType == OrderType.takeaway ? "Takeaway" : "Delivery"} • ${order.items.fold(0.0, (sum, i) => sum + i.qty).toStringAsFixed(0)} item',
                            ),
                            trailing: Text(
                              formatter.format(order.grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Muat Pesanan?'),
                                  content: const Text('Memuat pesanan ini akan menimpa keranjang POS saat ini.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        productState.whenData((prods) {
                                          ref.read(cartProvider.notifier).loadPendingOrder(order, prods);
                                        });
                                        context.pop(); // close alert dialog
                                        context.pop(); // close bottom sheet
                                        ToastHelper.showSuccess(context, 'Pesanan #${order.orderQueue} dimuat!');
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                      child: const Text('Muat'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartDetailSheet extends ConsumerWidget {
  final TextEditingController customerNameController;
  final TextEditingController orderNotesController;

  const _CartDetailSheet({
    required this.customerNameController,
    required this.orderNotesController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Detail Keranjang POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => context.pop(),
                  )
                ],
              ),
              const Divider(color: AppColors.border),

              // Customer name & Checkout Type Inputs
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<OrderType>(
                      initialValue: cart.orderType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Pesanan',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: OrderType.dineIn, child: Text('Dine-in')),
                        DropdownMenuItem(value: OrderType.takeaway, child: Text('Takeaway')),
                        DropdownMenuItem(value: OrderType.delivery, child: Text('Delivery')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(cartProvider.notifier).updateOrderType(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama / No Meja',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        ref.read(cartProvider.notifier).updateCustomerName(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Order Notes
              TextField(
                controller: orderNotesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pesanan',
                  hintText: 'Misal: Meja No.5, bungkus pisah kuah',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) {
                  ref.read(cartProvider.notifier).updateOrderNotes(val);
                },
              ),
              const SizedBox(height: 16),

              // Cart Items List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItemTile(context, ref, item, currencyFormat);
                  },
                ),
              ),

              // Summary & Action buttons
              const Divider(color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormat.format(cart.grandTotal),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ScaleImpactAnimation(
                      onTap: () {
                        // Clear Cart
                        ref.read(cartProvider.notifier).clearCart();
                        customerNameController.clear();
                        orderNotesController.clear();
                        context.pop();
                        ToastHelper.showInfo(context, 'Keranjang belanja dikosongkan');
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ScaleImpactAnimation(
                      onTap: () {
                        context.pop(); // close sheet
                        context.push('/pos/payment'); // Go to Payment Page
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proses Bayar',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemTile(BuildContext context, WidgetRef ref, CartItem item, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(item.product.sellingPrice),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Inline item-level note & Quantity adjustments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Custom note input field under item
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.pencil, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: item.notes)..selection = TextSelection.collapsed(offset: item.notes?.length ?? 0),
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan catatan...',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                        onChanged: (val) {
                          ref.read(cartProvider.notifier).updateItemNotes(item.product.id!, val.trim().isEmpty ? null : val.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleImpactAnimation(
                    onTap: () {
                      ref.read(cartProvider.notifier).updateQuantity(item.product.id!, item.quantity - 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                      child: const Icon(LucideIcons.minus, size: 14, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.quantity.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  ScaleImpactAnimation(
                    onTap: () {
                      ref.read(cartProvider.notifier).updateQuantity(item.product.id!, item.quantity + 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
