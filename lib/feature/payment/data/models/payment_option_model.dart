import '../../domain/entities/payment_option.dart';

class PaymentOptionModel extends PaymentOption {
  const PaymentOptionModel({
    super.id,
    required super.name,
    required super.type,
    super.icon,
    super.description,
    super.status,
    required super.createdAt,
  });

  /// Creates a [PaymentOptionModel] from a database Map.
  factory PaymentOptionModel.fromMap(Map<String, dynamic> map) {
    return PaymentOptionModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: PaymentOptionType.fromString(map['type'] as String),
      icon: map['icon'] as String?,
      description: map['description'] as String?,
      status: PaymentOptionStatus.fromString(map['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.toDbString,
      'icon': icon,
      'description': description,
      'status': status.toDbString,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [PaymentOption] entity to a [PaymentOptionModel].
  factory PaymentOptionModel.fromEntity(PaymentOption entity) {
    return PaymentOptionModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      icon: entity.icon,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [PaymentOption] entity.
  PaymentOption toEntity() {
    return PaymentOption(
      id: id,
      name: name,
      type: type,
      icon: icon,
      description: description,
      status: status,
      createdAt: createdAt,
    );
  }
}
