import '../../domain/entities/order_item.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    super.id,
    super.orderId,
    super.productId,
    required super.productName,
    required super.priceAtPurchase,
    required super.costPrice,
    required super.qty,
    super.discountId,
    super.discountValue,
    required super.subtotal,
    required super.createdAt,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      priceAtPurchase: (map['price_at_purchase'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      qty: (map['qty'] as num).toDouble(),
      discountId: map['discount_id'] as int?,
      discountValue: (map['discount_value'] as num? ?? 0.0).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price_at_purchase': priceAtPurchase,
      'cost_price': costPrice,
      'qty': qty,
      'discount_id': discountId,
      'discount_value': discountValue,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderItemModel.fromEntity(OrderItem entity) {
    return OrderItemModel(
      id: entity.id,
      orderId: entity.orderId,
      productId: entity.productId,
      productName: entity.productName,
      priceAtPurchase: entity.priceAtPurchase,
      costPrice: entity.costPrice,
      qty: entity.qty,
      discountId: entity.discountId,
      discountValue: entity.discountValue,
      subtotal: entity.subtotal,
      createdAt: entity.createdAt,
    );
  }

  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      productName: productName,
      priceAtPurchase: priceAtPurchase,
      costPrice: costPrice,
      qty: qty,
      discountId: discountId,
      discountValue: discountValue,
      subtotal: subtotal,
      createdAt: createdAt,
    );
  }

  @override
  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    double? priceAtPurchase,
    double? costPrice,
    double? qty,
    int? discountId,
    double? discountValue,
    double? subtotal,
    DateTime? createdAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      priceAtPurchase: priceAtPurchase ?? this.priceAtPurchase,
      costPrice: costPrice ?? this.costPrice,
      qty: qty ?? this.qty,
      discountId: discountId ?? this.discountId,
      discountValue: discountValue ?? this.discountValue,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
