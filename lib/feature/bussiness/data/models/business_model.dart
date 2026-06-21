import '../../domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    super.id,
    required super.name,
    super.email,
    super.phone,
    super.address,
    super.logo,
    super.taxRate = 0.0,
    super.footerMessage,
    required super.createdAt,
  });

  /// Creates a [BusinessModel] from a database Map.
  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      logo: map['logo'] as String?,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      footerMessage: map['footer_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'logo': logo,
      'tax_rate': taxRate,
      'footer_message': footerMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [Business] entity to a [BusinessModel].
  factory BusinessModel.fromEntity(Business entity) {
    return BusinessModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      logo: entity.logo,
      taxRate: entity.taxRate,
      footerMessage: entity.footerMessage,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [Business] entity.
  Business toEntity() {
    return Business(
      id: id,
      name: name,
      email: email,
      phone: phone,
      address: address,
      logo: logo,
      taxRate: taxRate,
      footerMessage: footerMessage,
      createdAt: createdAt,
    );
  }
}
