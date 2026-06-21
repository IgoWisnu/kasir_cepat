import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/bussiness/domain/entities/business.dart';
import 'package:kasir_cepat/feature/bussiness/domain/repositories/business_repository.dart';
import 'package:kasir_cepat/feature/bussiness/domain/usecases/delete_business.dart';
import 'package:kasir_cepat/feature/bussiness/domain/usecases/get_business.dart';
import 'package:kasir_cepat/feature/bussiness/domain/usecases/save_business.dart';

class FakeBusinessRepository implements BusinessRepository {
  Business? mockBusiness;
  int mockSavedId = 1;
  bool getCalled = false;
  bool saveCalled = false;
  bool deleteCalled = false;
  int? deletedId;

  @override
  Future<Either<Failure, Business?>> getBusiness() async {
    getCalled = true;
    return Right(mockBusiness);
  }

  @override
  Future<Either<Failure, int>> saveBusiness(Business business) async {
    saveCalled = true;
    mockBusiness = business;
    return Right(mockSavedId);
  }

  @override
  Future<Either<Failure, void>> deleteBusiness(int id) async {
    deleteCalled = true;
    deletedId = id;
    mockBusiness = null;
    return const Right(null);
  }
}

void main() {
  late FakeBusinessRepository repository;
  late GetBusiness getBusinessUseCase;
  late SaveBusiness saveBusinessUseCase;
  late DeleteBusiness deleteBusinessUseCase;

  setUp(() {
    repository = FakeBusinessRepository();
    getBusinessUseCase = GetBusiness(repository);
    saveBusinessUseCase = SaveBusiness(repository);
    deleteBusinessUseCase = DeleteBusiness(repository);
  });

  final tDateTime = DateTime(2026, 6, 19);
  final tBusiness = Business(
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

  group('GetBusiness UseCase', () {
    test('should fetch business profile from the repository', () async {
      // Arrange
      repository.mockBusiness = tBusiness;
      // Act
      final result = await getBusinessUseCase(NoParams());
      // Assert
      expect(result, Right(tBusiness));
      expect(repository.getCalled, isTrue);
    });
  });

  group('SaveBusiness UseCase', () {
    test('should save business profile into the repository', () async {
      // Arrange
      repository.mockSavedId = 99;
      // Act
      final result = await saveBusinessUseCase(tBusiness);
      // Assert
      expect(result, const Right(99));
      expect(repository.saveCalled, isTrue);
      expect(repository.mockBusiness, equals(tBusiness));
    });
  });

  group('DeleteBusiness UseCase', () {
    test('should delete business profile from the repository', () async {
      // Arrange
      repository.mockBusiness = tBusiness;
      // Act
      final result = await deleteBusinessUseCase(1);
      // Assert
      expect(result, const Right(null));
      expect(repository.deleteCalled, isTrue);
      expect(repository.deletedId, 1);
      expect(repository.mockBusiness, isNull);
    });
  });
}
