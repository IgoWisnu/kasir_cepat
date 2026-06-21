import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int? id;
  final int? orderId;
  final int? productId;
  final String productName;
  final double priceAtPurchase;
  final double costPrice;
  final double qty;
  final int? discountId;
  final double discountValue;
  final double subtotal;
  final DateTime createdAt;

  const OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.productName,
    required this.priceAtPurchase,
    required this.costPrice,
    required this.qty,
    this.discountId,
    this.discountValue = 0.0,
    required this.subtotal,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        priceAtPurchase,
        costPrice,
        qty,
        discountId,
        discountValue,
        subtotal,
        createdAt,
      ];

  OrderItem copyWith({
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
    return OrderItem(
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
