import 'package:equatable/equatable.dart';
import 'stock_transaction.dart';

enum StockBatchType {
  restock,
  opname;

  static StockBatchType fromString(String value) {
    switch (value) {
      case 'restock':
        return StockBatchType.restock;
      case 'opname':
        return StockBatchType.opname;
      default:
        return StockBatchType.restock;
    }
  }
}

class StockBatch extends Equatable {
  final int? id;
  final String batchNo;
  final StockBatchType type;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<StockTransaction>? items; // List of movements in this batch

  const StockBatch({
    this.id,
    required this.batchNo,
    required this.type,
    this.status = 'completed',
    this.notes,
    required this.createdAt,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        batchNo,
        type,
        status,
        notes,
        createdAt,
        items,
      ];
}
