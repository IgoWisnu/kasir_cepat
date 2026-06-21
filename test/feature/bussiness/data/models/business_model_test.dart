import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/feature/bussiness/data/models/business_model.dart';
import 'package:kasir_cepat/feature/bussiness/domain/entities/business.dart';

void main() {
  final tDateTime = DateTime(2026, 6, 19, 12, 0, 0);
  
  final tBusinessModel = BusinessModel(
    id: 1,
    name: 'Toko Kopi Maju',
    email: 'kopi@maju.com',
    phone: '0811223344',
    address: 'Jl. Merdeka No. 10',
    logo: 'assets/logo.png',
    taxRate: 10.0,
    footerMessage: 'Terima kasih!',
    createdAt: tDateTime,
  );

  final tMap = {
    'id': 1,
    'name': 'Toko Kopi Maju',
    'email': 'kopi@maju.com',
    'phone': '0811223344',
    'address': 'Jl. Merdeka No. 10',
    'logo': 'assets/logo.png',
    'tax_rate': 10.0,
    'footer_message': 'Terima kasih!',
    'created_at': tDateTime.toIso8601String(),
  };

  group('BusinessModel', () {
    test('should be a subclass of Business entity', () {
      expect(tBusinessModel, isA<Business>());
    });

    test('fromMap should return a valid model from Map', () {
      // Act
      final result = BusinessModel.fromMap(tMap);
      // Assert
      expect(result, equals(tBusinessModel));
      expect(result.id, 1);
      expect(result.name, 'Toko Kopi Maju');
      expect(result.createdAt, tDateTime);
    });

    test('toMap should return a Map containing correct data', () {
      // Act
      final result = tBusinessModel.toMap();
      // Assert
      expect(result, equals(tMap));
    });

    test('toEntity should return a valid Business entity', () {
      // Act
      final result = tBusinessModel.toEntity();
      // Assert
      expect(result, isA<Business>());
      expect(result.name, tBusinessModel.name);
      expect(result.email, tBusinessModel.email);
    });

    test('fromEntity should return a valid BusinessModel', () {
      // Arrange
      final entity = Business(
        id: 2,
        name: 'Warung Baru',
        email: null,
        phone: '089988',
        address: null,
        logo: null,
        taxRate: 0.0,
        footerMessage: null,
        createdAt: tDateTime,
      );
      // Act
      final result = BusinessModel.fromEntity(entity);
      // Assert
      expect(result, isA<BusinessModel>());
      expect(result.id, 2);
      expect(result.name, 'Warung Baru');
      expect(result.email, isNull);
    });
  });
}
