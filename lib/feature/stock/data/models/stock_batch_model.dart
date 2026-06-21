import '../../domain/entities/stock_batch.dart';
import 'stock_transaction_model.dart';

class StockBatchModel extends StockBatch {
  const StockBatchModel({
    super.id,
    required super.batchNo,
    required super.type,
    super.status = 'completed',
    super.notes,
    required super.createdAt,
    super.items,
  });

  /// Creates a [StockBatchModel] from a database Map.
  factory StockBatchModel.fromMap(Map<String, dynamic> map, {List<StockTransactionModel>? items}) {
    return StockBatchModel(
      id: map['id'] as int?,
      batchNo: map['batch_no'] as String,
      type: StockBatchType.fromString(map['type'] as String),
      status: map['status'] as String? ?? 'completed',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items?.map((item) => item.toEntity()).toList(),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'batch_no': batchNo,
      'type': type.name,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [StockBatch] entity to a [StockBatchModel].
  factory StockBatchModel.fromEntity(StockBatch entity) {
    return StockBatchModel(
      id: entity.id,
      batchNo: entity.batchNo,
      type: entity.type,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      items: entity.items?.map((e) => StockTransactionModel.fromEntity(e)).toList(),
    );
  }

  /// Converts this model back to a domain [StockBatch] entity.
  StockBatch toEntity() {
    return StockBatch(
      id: id,
      batchNo: batchNo,
      type: type,
      status: status,
      notes: notes,
      createdAt: createdAt,
      items: items,
    );
  }
}
