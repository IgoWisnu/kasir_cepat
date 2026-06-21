import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/feature/unit/data/models/unit_model.dart';
import 'package:kasir_cepat/feature/unit/domain/entities/unit_entity.dart';

void main() {
  final tDateTime = DateTime(2026, 6, 19, 12, 0, 0);
  
  final tUnitModel = UnitModel(
    id: 1,
    name: 'Kilogram',
    abbreviation: 'kg',
    createdAt: tDateTime,
  );

  final tMap = {
    'id': 1,
    'name': 'Kilogram',
    'abbreviation': 'kg',
    'created_at': tDateTime.toIso8601String(),
  };

  group('UnitModel', () {
    test('should be a subclass of Unit entity', () {
      expect(tUnitModel, isA<Unit>());
    });

    test('fromMap should return a valid model from Map', () {
      // Act
      final result = UnitModel.fromMap(tMap);
      // Assert
      expect(result, equals(tUnitModel));
    });

    test('toMap should return a Map containing correct data', () {
      // Act
      final result = tUnitModel.toMap();
      // Assert
      expect(result, equals(tMap));
    });

    test('toEntity should return a valid Unit entity', () {
      // Act
      final result = tUnitModel.toEntity();
      // Assert
      expect(result, isA<Unit>());
      expect(result.name, tUnitModel.name);
      expect(result.abbreviation, tUnitModel.abbreviation);
    });

    test('fromEntity should return a valid UnitModel', () {
      // Arrange
      final entity = Unit(
        id: 2,
        name: 'Pieces',
        abbreviation: 'pcs',
        createdAt: DateTime(2026, 6, 19),
      );
      // Act
      final result = UnitModel.fromEntity(entity);
      // Assert
      expect(result, isA<UnitModel>());
      expect(result.id, 2);
      expect(result.name, 'Pieces');
    });
  });
}
