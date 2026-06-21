import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/discount/domain/entities/discount.dart';
import 'package:kasir_cepat/feature/discount/domain/repositories/discount_repository.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/delete_discount.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/get_discounts.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/save_discount.dart';

class FakeDiscountRepository implements DiscountRepository {
  List<Discount> mockDiscounts = [];
  int mockSavedId = 1;
  bool getCalled = false;
  bool saveCalled = false;
  bool deleteCalled = false;
  int? deletedId;

  @override
  Future<Either<Failure, List<Discount>>> getDiscounts() async {
    getCalled = true;
    return Right(mockDiscounts);
  }

  @override
  Future<Either<Failure, int>> saveDiscount(Discount discount) async {
    saveCalled = true;
    mockDiscounts.add(discount);
    return Right(mockSavedId);
  }

  @override
  Future<Either<Failure, void>> deleteDiscount(int id) async {
    deleteCalled = true;
    deletedId = id;
    mockDiscounts.removeWhere((item) => item.id == id);
    return const Right(null);
  }
}

void main() {
  late FakeDiscountRepository repository;
  late GetDiscounts getDiscountsUseCase;
  late SaveDiscount saveDiscountUseCase;
  late DeleteDiscount deleteDiscountUseCase;

  setUp(() {
    repository = FakeDiscountRepository();
    getDiscountsUseCase = GetDiscounts(repository);
    saveDiscountUseCase = SaveDiscount(repository);
    deleteDiscountUseCase = DeleteDiscount(repository);
  });

  final tDateTime = DateTime(2026, 6, 19);
  final tDiscount = Discount(
    id: 1,
    name: 'Diskon Akhir Tahun',
    description: 'Promo akhir tahun 2026',
    valueType: 'percentage',
    value: 20.0,
    startDate: null,
    endDate: null,
    isActive: true,
    createdAt: tDateTime,
  );

  group('GetDiscounts UseCase', () {
    test('should fetch discounts list from the repository', () async {
      // Arrange
      repository.mockDiscounts = [tDiscount];
      // Act
      final result = await getDiscountsUseCase(NoParams());
      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail: ${failure.message}'),
        (discounts) => expect(discounts, equals([tDiscount])),
      );
      expect(repository.getCalled, isTrue);
    });
  });

  group('SaveDiscount UseCase', () {
    test('should save discount into the repository', () async {
      // Arrange
      repository.mockSavedId = 10;
      // Act
      final result = await saveDiscountUseCase(tDiscount);
      // Assert
      expect(result, const Right(10));
      expect(repository.saveCalled, isTrue);
      expect(repository.mockDiscounts, contains(tDiscount));
    });
  });

  group('DeleteDiscount UseCase', () {
    test('should delete discount from the repository', () async {
      // Arrange
      repository.mockDiscounts = [tDiscount];
      // Act
      final result = await deleteDiscountUseCase(1);
      // Assert
      expect(result, const Right(null));
      expect(repository.deleteCalled, isTrue);
      expect(repository.deletedId, 1);
      expect(repository.mockDiscounts, isEmpty);
    });
  });
}
