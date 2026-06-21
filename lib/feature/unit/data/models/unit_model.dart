import '../../domain/entities/unit_entity.dart';

class UnitModel extends Unit {
  const UnitModel({
    super.id,
    required super.name,
    required super.abbreviation,
    required super.createdAt,
  });

  /// Creates a [UnitModel] from a database Map.
  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [Unit] entity to a [UnitModel].
  factory UnitModel.fromEntity(Unit entity) {
    return UnitModel(
      id: entity.id,
      name: entity.name,
      abbreviation: entity.abbreviation,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [Unit] entity.
  Unit toEntity() {
    return Unit(
      id: id,
      name: name,
      abbreviation: abbreviation,
      createdAt: createdAt,
    );
  }
}
