import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/domain/entities/product.dart';
import '../../../order/domain/entities/order.dart';

class CartItem {
  final Product product;
  final double quantity;
  final double discountValue; // Item-level discount amount (fixed)
  final String? notes; // Item-level custom note

  CartItem({
    required this.product,
    this.quantity = 1.0,
    this.discountValue = 0.0,
    this.notes,
  });

  double get subtotal => (product.sellingPrice - discountValue) * quantity;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? discountValue,
    String? notes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountValue: discountValue ?? this.discountValue,
      notes: notes ?? this.notes,
    );
  }
}

class CartState {
  final int? editingOrderId;
  final String? invoiceNumber;
  final int? orderQueue;
  final List<CartItem> items;
  final OrderType orderType;
  final String customerName;
  final String notes; // Order-level notes

  CartState({
    this.editingOrderId,
    this.invoiceNumber,
    this.orderQueue,
    this.items = const [],
    this.orderType = OrderType.dineIn,
    this.customerName = '',
    this.notes = '',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(
    0.0,
    (sum, item) => sum + (item.discountValue * item.quantity),
  );
  double get grandTotal => subtotal; // we can add tax or discounts here

  CartState copyWith({
    int? editingOrderId,
    String? invoiceNumber,
    int? orderQueue,
    List<CartItem>? items,
    OrderType? orderType,
    String? customerName,
    String? notes,
  }) {
    return CartState(
      editingOrderId: editingOrderId ?? this.editingOrderId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderQueue: orderQueue ?? this.orderQueue,
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(Product product, {double qty = 1.0}) {
    final idx = state.items.indexWhere((item) => item.product.id == product.id);
    if (idx != -1) {
      final existingItem = state.items[idx];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[idx] = existingItem.copyWith(
        quantity: existingItem.quantity + qty,
      );
      state = state.copyWith(items: updatedList);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product, quantity: qty),
        ],
      );
    }
  }

  void updateQuantity(int productId, double qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    final updatedList = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: qty);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedList);
  }

  void updateItemDiscount(int productId, double discount) {
    final updatedList = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(discountValue: discount);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedList);
  }

  void updateItemNotes(int productId, String? notes) {
    final updatedList = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(notes: notes);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedList);
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void updateCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void updateOrderNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    state = CartState();
  }

  /// Loads an existing pending order back into the cart for editing.
  void loadPendingOrder(Order order, List<Product> availableProducts) {
    final cartItems = order.items.map((item) {
      // Find matching product in available catalog, or build fallback
      final product = availableProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(
          id: item.productId,
          name: item.productName,
          sellingPrice: item.priceAtPurchase,
          costPrice: item.costPrice,
          stockQuantity: 0,
          isTrackStock: false,
          createdAt: DateTime.now(),
        ),
      );

      return CartItem(
        product: product,
        quantity: item.qty,
        discountValue: item.discountValue,
        notes: null,
      );
    }).toList();

    state = CartState(
      editingOrderId: order.id,
      invoiceNumber: order.invoiceNumber,
      orderQueue: order.orderQueue,
      items: cartItems,
      orderType: order.orderType,
      customerName: order.customerName ?? '',
      notes: order.notes ?? '',
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
