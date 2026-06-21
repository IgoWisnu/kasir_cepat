import 'package:equatable/equatable.dart';

class StockMovementItem extends Equatable {
  final int id;
  final int? productId;
  final String productName;
  final String productSku;
  final double quantity;
  final String type; // 'stock_in', 'stock_out', 'sale', 'adjustment', etc.
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  const StockMovementItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.type,
    this.reference,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productSku,
        quantity,
        type,
        reference,
        notes,
        createdAt,
      ];
}

class StockMovementReport extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final List<StockMovementItem> movements;

  const StockMovementReport({
    required this.startDate,
    required this.endDate,
    required this.movements,
  });

  @override
  List<Object?> get props => [startDate, endDate, movements];
}
