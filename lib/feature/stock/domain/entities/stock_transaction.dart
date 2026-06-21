import 'package:equatable/equatable.dart';

enum StockTransactionType {
  stockIn,
  stockOut,
  sale,
  adjustment,
  restock,
  opname;

  static StockTransactionType fromString(String value) {
    switch (value) {
      case 'stock_in':
        return StockTransactionType.stockIn;
      case 'stock_out':
        return StockTransactionType.stockOut;
      case 'sale':
        return StockTransactionType.sale;
      case 'adjustment':
        return StockTransactionType.adjustment;
      case 'restock':
        return StockTransactionType.restock;
      case 'opname':
        return StockTransactionType.opname;
      default:
        return StockTransactionType.adjustment;
    }
  }

  String get toDbString {
    switch (this) {
      case StockTransactionType.stockIn:
        return 'stock_in';
      case StockTransactionType.stockOut:
        return 'stock_out';
      case StockTransactionType.sale:
        return 'sale';
      case StockTransactionType.adjustment:
        return 'adjustment';
      case StockTransactionType.restock:
        return 'restock';
      case StockTransactionType.opname:
        return 'opname';
    }
  }
}

class StockTransaction extends Equatable {
  final int? id;
  final int productId;
  final String? productName; // Loaded via SQL JOIN for UI convenience
  final int? batchId;
  final double quantity; // Positive for stock-in, Negative for stock-out
  final StockTransactionType type;
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  const StockTransaction({
    this.id,
    required this.productId,
    this.productName,
    this.batchId,
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
        batchId,
        quantity,
        type,
        reference,
        notes,
        createdAt,
      ];
}
