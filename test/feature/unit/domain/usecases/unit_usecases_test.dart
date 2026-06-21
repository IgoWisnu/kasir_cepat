import 'package:dartz/dartz.dart' hide Unit;
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/unit/domain/entities/unit_entity.dart';
import 'package:kasir_cepat/feature/unit/domain/repositories/unit_repository.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/delete_unit.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/get_units.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/save_unit.dart';

class FakeUnitRepository implements UnitRepository {
  List<Unit> mockUnits = [];
  int mockSavedId = 1;
  bool getCalled = false;
  bool saveCalled = false;
  bool deleteCalled = false;
  int? deletedId;

  @override
  Future<Either<Failure, List<Unit>>> getUnits() async {
    getCalled = true;
    return Right(mockUnits);
  }

  @override
  Future<Either<Failure, int>> saveUnit(Unit unit) async {
    saveCalled = true;
    mockUnits.add(unit);
    return Right(mockSavedId);
  }

  @override
  Future<Either<Failure, void>> deleteUnit(int id) async {
    deleteCalled = true;
    deletedId = id;
    mockUnits.removeWhere((item) => item.id == id);
    return const Right(null);
  }
}

void main() {
  late FakeUnitRepository repository;
  late GetUnits getUnitsUseCase;
  late SaveUnit saveUnitUseCase;
  late DeleteUnit deleteUnitUseCase;

  setUp(() {
    repository = FakeUnitRepository();
    getUnitsUseCase = GetUnits(repository);
    saveUnitUseCase = SaveUnit(repository);
    deleteUnitUseCase = DeleteUnit(repository);
  });

  final tDateTime = DateTime(2026, 6, 19);
  final tUnit = Unit(
    id: 1,
    name: 'Pieces',
    abbreviation: 'pcs',
    createdAt: tDateTime,
  );

  group('GetUnits UseCase', () {
    test('should fetch units list from the repository', () async {
      // Arrange
      repository.mockUnits = [tUnit];
      // Act
      final result = await getUnitsUseCase(NoParams());
      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail: ${failure.message}'),
        (units) => expect(units, equals([tUnit])),
      );
      expect(repository.getCalled, isTrue);
    });
  });

  group('SaveUnit UseCase', () {
    test('should save unit into the repository', () async {
      // Arrange
      repository.mockSavedId = 10;
      // Act
      final result = await saveUnitUseCase(tUnit);
      // Assert
      expect(result, const Right(10));
      expect(repository.saveCalled, isTrue);
      expect(repository.mockUnits, contains(tUnit));
    });
  });

  group('DeleteUnit UseCase', () {
    test('should delete unit from the repository', () async {
      // Arrange
      repository.mockUnits = [tUnit];
      // Act
      final result = await deleteUnitUseCase(1);
      // Assert
      expect(result, const Right(null));
      expect(repository.deleteCalled, isTrue);
      expect(repository.deletedId, 1);
      expect(repository.mockUnits, isEmpty);
    });
  });
}
