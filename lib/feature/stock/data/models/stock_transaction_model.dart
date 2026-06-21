import '../../domain/entities/stock_transaction.dart';

class StockTransactionModel extends StockTransaction {
  const StockTransactionModel({
    super.id,
    required super.productId,
    super.productName,
    super.batchId,
    required super.quantity,
    required super.type,
    super.reference,
    super.notes,
    required super.createdAt,
  });

  /// Creates a [StockTransactionModel] from a database Map.
  factory StockTransactionModel.fromMap(Map<String, dynamic> map) {
    return StockTransactionModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?, // Loaded from JOIN
      batchId: map['batch_id'] as int?,
      quantity: (map['quantity'] as num).toDouble(),
      type: StockTransactionType.fromString(map['type'] as String),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'batch_id': batchId,
      'quantity': quantity,
      'type': type.toDbString,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [StockTransaction] entity to a [StockTransactionModel].
  factory StockTransactionModel.fromEntity(StockTransaction entity) {
    return StockTransactionModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      batchId: entity.batchId,
      quantity: entity.quantity,
      type: entity.type,
      reference: entity.reference,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [StockTransaction] entity.
  StockTransaction toEntity() {
    return StockTransaction(
      id: id,
      productId: productId,
      productName: productName,
      batchId: batchId,
      quantity: quantity,
      type: type,
      reference: reference,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
