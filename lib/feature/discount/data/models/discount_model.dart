import '../../domain/entities/discount.dart';

class DiscountModel extends Discount {
  const DiscountModel({
    super.id,
    required super.name,
    super.description,
    required super.valueType,
    required super.value,
    super.startDate,
    super.endDate,
    super.isActive = true,
    required super.createdAt,
  });

  /// Creates a [DiscountModel] from a database Map.
  factory DiscountModel.fromMap(Map<String, dynamic> map) {
    return DiscountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      valueType: map['value_type'] as String,
      value: (map['value'] as num).toDouble(),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'value_type': valueType,
      'value': value,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [Discount] entity to a [DiscountModel].
  factory DiscountModel.fromEntity(Discount entity) {
    return DiscountModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      valueType: entity.valueType,
      value: entity.value,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [Discount] entity.
  Discount toEntity() {
    return Discount(
      id: id,
      name: name,
      description: description,
      valueType: valueType,
      value: value,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
