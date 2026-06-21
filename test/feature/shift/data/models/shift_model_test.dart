import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/feature/shift/data/models/shift_model.dart';
import 'package:kasir_cepat/feature/shift/domain/entities/shift.dart';

void main() {
  final tDateTime = DateTime(2026, 6, 21, 12, 0, 0);

  final tShiftModel = ShiftModel(
    id: 1,
    startTime: tDateTime,
    endTime: tDateTime.add(const Duration(hours: 8)),
    status: ShiftStatus.closed,
    userId: 2,
    cashStart: 100000.0,
    cashEnd: 250000.0,
    cashDifferent: 0.0,
    notes: 'Shift pagi lancar',
  );

  final tMap = {
    'id': 1,
    'start_time': tDateTime.toIso8601String(),
    'end_time': tDateTime.add(const Duration(hours: 8)).toIso8601String(),
    'status': 'closed',
    'user_id': 2,
    'cash_start': 100000.0,
    'cash_end': 250000.0,
    'cash_different': 0.0,
    'notes': 'Shift pagi lancar',
  };

  group('ShiftModel', () {
    test('should be a subclass of Shift entity', () {
      expect(tShiftModel, isA<Shift>());
    });

    test('fromMap should return a valid model from Map', () {
      // Act
      final result = ShiftModel.fromMap(tMap);
      // Assert
      expect(result, equals(tShiftModel));
      expect(result.id, 1);
      expect(result.status, ShiftStatus.closed);
      expect(result.startTime, tDateTime);
    });

    test('toMap should return a Map containing correct data', () {
      // Act
      final result = tShiftModel.toMap();
      // Assert
      expect(result, equals(tMap));
    });

    test('toEntity should return a valid Shift entity', () {
      // Act
      final result = tShiftModel.toEntity();
      // Assert
      expect(result, isA<Shift>());
      expect(result.startTime, tShiftModel.startTime);
      expect(result.cashStart, tShiftModel.cashStart);
    });

    test('fromEntity should return a valid ShiftModel', () {
      // Arrange
      final entity = Shift(
        id: 2,
        startTime: tDateTime,
        endTime: null,
        status: ShiftStatus.open,
        userId: 1,
        cashStart: 50000.0,
        cashEnd: null,
        cashDifferent: null,
        notes: null,
      );
      // Act
      final result = ShiftModel.fromEntity(entity);
      // Assert
      expect(result, isA<ShiftModel>());
      expect(result.id, 2);
      expect(result.status, ShiftStatus.open);
      expect(result.cashEnd, isNull);
    });
  });
}
