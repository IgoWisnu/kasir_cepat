import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum OrderType {
  dineIn,
  takeaway,
  delivery;

  static OrderType fromString(String value) {
    switch (value) {
      case 'dine-in':
        return OrderType.dineIn;
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      default:
        return OrderType.takeaway;
    }
  }

  String get toDbString {
    switch (this) {
      case OrderType.dineIn:
        return 'dine-in';
      case OrderType.takeaway:
        return 'takeaway';
      case OrderType.delivery:
        return 'delivery';
    }
  }
}

enum OrderStatus {
  newOrder,
  processing,
  preparing,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'new':
        return OrderStatus.newOrder;
      case 'processing':
        return OrderStatus.processing;
      case 'preparing':
        return OrderStatus.preparing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.newOrder;
    }
  }

  String get toDbString {
    switch (this) {
      case OrderStatus.newOrder:
        return 'new';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

enum PaymentStatus {
  pending,
  partial,
  paid,
  refunded;

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get toDbString {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.partial:
        return 'partial';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}

class Order extends Equatable {
  final int? id;
  final String? invoiceNumber;
  final int orderQueue;
  final String? customerName;
  final OrderType orderType;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final int? discountId;
  final double discountValue;
  final String? discountType;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;
  final int? paymentOptionId;
  final double? cashReceived;
  final double? changeGiven;
  final double paidAmount;
  final String? notes;
  final int? userId;
  final int? shiftId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    this.invoiceNumber,
    required this.orderQueue,
    this.customerName,
    required this.orderType,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subtotal,
    this.discountId,
    this.discountValue = 0.0,
    this.discountType,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.grandTotal,
    this.paymentOptionId,
    this.cashReceived,
    this.changeGiven,
    this.paidAmount = 0.0,
    this.notes,
    this.userId,
    this.shiftId,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        orderQueue,
        customerName,
        orderType,
        orderStatus,
        paymentStatus,
        subtotal,
        discountId,
        discountValue,
        discountType,
        taxRate,
        taxAmount,
        grandTotal,
        paymentOptionId,
        cashReceived,
        changeGiven,
        paidAmount,
        notes,
        userId,
        shiftId,
        createdAt,
        updatedAt,
        items,
      ];

  Order copyWith({
    int? id,
    String? invoiceNumber,
    int? orderQueue,
    String? customerName,
    OrderType? orderType,
    OrderStatus? orderStatus,
    PaymentStatus? paymentStatus,
    double? subtotal,
    int? discountId,
    double? discountValue,
    String? discountType,
    double? taxRate,
    double? taxAmount,
    double? grandTotal,
    int? paymentOptionId,
    double? cashReceived,
    double? changeGiven,
    double? paidAmount,
    String? notes,
    int? userId,
    int? shiftId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderQueue: orderQueue ?? this.orderQueue,
      customerName: customerName ?? this.customerName,
      orderType: orderType ?? this.orderType,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      discountId: discountId ?? this.discountId,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentOptionId: paymentOptionId ?? this.paymentOptionId,
      cashReceived: cashReceived ?? this.cashReceived,
      changeGiven: changeGiven ?? this.changeGiven,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
