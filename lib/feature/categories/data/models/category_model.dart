import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    super.id,
    required super.name,
    super.description,
    required super.createdAt,
  });

  /// Creates a [CategoryModel] from a database Map.
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [Category] entity to a [CategoryModel].
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [Category] entity.
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
    );
  }
}
