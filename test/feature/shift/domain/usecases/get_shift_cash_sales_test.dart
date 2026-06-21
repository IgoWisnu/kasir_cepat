import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/feature/shift/domain/entities/shift.dart';
import 'package:kasir_cepat/feature/shift/domain/repositories/shift_repository.dart';
import 'package:kasir_cepat/feature/shift/domain/usecases/get_shift_cash_sales.dart';

class FakeShiftRepository implements ShiftRepository {
  double mockCashSales = 0.0;
  bool getCashSalesCalled = false;
  int? requestedShiftId;

  @override
  Future<Either<Failure, double>> getShiftCashSales(int shiftId) async {
    getCashSalesCalled = true;
    requestedShiftId = shiftId;
    return Right(mockCashSales);
  }

  @override
  Future<Either<Failure, int>> startShift({
    required double cashStart,
    int? userId,
    String? notes,
  }) async {
    return const Right(1);
  }

  @override
  Future<Either<Failure, void>> closeShift({
    required int shiftId,
    required double cashEnd,
    String? notes,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Shift?>> getActiveShift() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Shift>>> getShifts() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Shift?>> getShiftById(int id) async {
    return const Right(null);
  }
}

void main() {
  late FakeShiftRepository repository;
  late GetShiftCashSales usecase;

  setUp(() {
    repository = FakeShiftRepository();
    usecase = GetShiftCashSales(repository);
  });

  test('should get shift cash sales from the repository', () async {
    // Arrange
    repository.mockCashSales = 150000.0;
    // Act
    final result = await usecase(123);
    // Assert
    expect(result, const Right(150000.0));
    expect(repository.getCashSalesCalled, isTrue);
    expect(repository.requestedShiftId, 123);
  });
}
