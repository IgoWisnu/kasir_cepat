import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/feature/categories/data/models/category_model.dart';
import 'package:kasir_cepat/feature/categories/domain/entities/category.dart';

void main() {
  final tDateTime = DateTime(2026, 6, 19, 12, 0, 0);

  final tCategoryModel = CategoryModel(
    id: 1,
    name: 'Makanan',
    description: 'Kategori untuk makanan',
    createdAt: tDateTime,
  );

  final tMap = {
    'id': 1,
    'name': 'Makanan',
    'description': 'Kategori untuk makanan',
    'created_at': tDateTime.toIso8601String(),
  };

  group('CategoryModel', () {
    test('should be a subclass of Category entity', () {
      expect(tCategoryModel, isA<Category>());
    });

    test('fromMap should return a valid model from Map', () {
      // Act
      final result = CategoryModel.fromMap(tMap);
      // Assert
      expect(result, equals(tCategoryModel));
    });

    test('toMap should return a Map containing correct data', () {
      // Act
      final result = tCategoryModel.toMap();
      // Assert
      expect(result, equals(tMap));
    });

    test('toEntity should return a valid Category entity', () {
      // Act
      final result = tCategoryModel.toEntity();
      // Assert
      expect(result, isA<Category>());
      expect(result.name, tCategoryModel.name);
      expect(result.description, tCategoryModel.description);
    });

    test('fromEntity should return a valid CategoryModel', () {
      // Arrange
      final entity = Category(
        id: 2,
        name: 'Minuman',
        description: 'Kategori untuk minuman',
        createdAt: DateTime(2026, 6, 19),
      );
      // Act
      final result = CategoryModel.fromEntity(entity);
      // Assert
      expect(result, isA<CategoryModel>());
      expect(result.id, 2);
      expect(result.name, 'Minuman');
      expect(result.description, 'Kategori untuk minuman');
    });
  });
}
