import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/feature/discount/data/models/discount_model.dart';
import 'package:kasir_cepat/feature/discount/domain/entities/discount.dart';

void main() {
  final tDateTime = DateTime(2026, 6, 19, 12, 0, 0);
  final tStartDate = DateTime(2026, 6, 20, 0, 0, 0);
  final tEndDate = DateTime(2026, 6, 30, 23, 59, 59);

  final tDiscountModel = DiscountModel(
    id: 1,
    name: 'Diskon Natal',
    description: 'Promo akhir tahun',
    valueType: 'percentage',
    value: 10.0,
    startDate: tStartDate,
    endDate: tEndDate,
    isActive: true,
    createdAt: tDateTime,
  );

  final tMap = {
    'id': 1,
    'name': 'Diskon Natal',
    'description': 'Promo akhir tahun',
    'value_type': 'percentage',
    'value': 10.0,
    'start_date': tStartDate.toIso8601String(),
    'end_date': tEndDate.toIso8601String(),
    'is_active': 1,
    'created_at': tDateTime.toIso8601String(),
  };

  group('DiscountModel', () {
    test('should be a subclass of Discount entity', () {
      expect(tDiscountModel, isA<Discount>());
    });

    test('fromMap should return a valid model from Map', () {
      // Act
      final result = DiscountModel.fromMap(tMap);
      // Assert
      expect(result, equals(tDiscountModel));
    });

    test('fromMap should handle null dates and description', () {
      // Arrange
      final mapWithNulls = {
        'id': 2,
        'name': 'Diskon Member',
        'description': null,
        'value_type': 'fixed',
        'value': 5000.0,
        'start_date': null,
        'end_date': null,
        'is_active': 0,
        'created_at': tDateTime.toIso8601String(),
      };
      // Act
      final result = DiscountModel.fromMap(mapWithNulls);
      // Assert
      expect(result.id, 2);
      expect(result.description, isNull);
      expect(result.startDate, isNull);
      expect(result.endDate, isNull);
      expect(result.isActive, isFalse);
    });

    test('toMap should return a Map containing correct data', () {
      // Act
      final result = tDiscountModel.toMap();
      // Assert
      expect(result, equals(tMap));
    });

    test('toEntity should return a valid Discount entity', () {
      // Act
      final result = tDiscountModel.toEntity();
      // Assert
      expect(result, isA<Discount>());
      expect(result.name, tDiscountModel.name);
      expect(result.valueType, tDiscountModel.valueType);
      expect(result.value, tDiscountModel.value);
    });

    test('fromEntity should return a valid DiscountModel', () {
      // Arrange
      final entity = Discount(
        id: 2,
        name: 'Diskon Karyawan',
        description: 'Potongan khusus staff',
        valueType: 'fixed',
        value: 15000.0,
        startDate: null,
        endDate: null,
        isActive: true,
        createdAt: tDateTime,
      );
      // Act
      final result = DiscountModel.fromEntity(entity);
      // Assert
      expect(result, isA<DiscountModel>());
      expect(result.id, 2);
      expect(result.name, 'Diskon Karyawan');
      expect(result.value, 15000.0);
    });
  });
}
