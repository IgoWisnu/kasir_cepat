import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/categories/domain/entities/category.dart';
import 'package:kasir_cepat/feature/categories/domain/repositories/category_repository.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/delete_category.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/get_categories.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/save_category.dart';

class FakeCategoryRepository implements CategoryRepository {
  List<Category> mockCategories = [];
  int mockSavedId = 1;
  bool getCalled = false;
  bool saveCalled = false;
  bool deleteCalled = false;
  int? deletedId;

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    getCalled = true;
    return Right(mockCategories);
  }

  @override
  Future<Either<Failure, int>> saveCategory(Category category) async {
    saveCalled = true;
    mockCategories.add(category);
    return Right(mockSavedId);
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    deleteCalled = true;
    deletedId = id;
    mockCategories.removeWhere((item) => item.id == id);
    return const Right(null);
  }
}

void main() {
  late FakeCategoryRepository repository;
  late GetCategories getCategoriesUseCase;
  late SaveCategory saveCategoryUseCase;
  late DeleteCategory deleteCategoryUseCase;

  setUp(() {
    repository = FakeCategoryRepository();
    getCategoriesUseCase = GetCategories(repository);
    saveCategoryUseCase = SaveCategory(repository);
    deleteCategoryUseCase = DeleteCategory(repository);
  });

  final tDateTime = DateTime(2026, 6, 19);
  final tCategory = Category(
    id: 1,
    name: 'Makanan',
    description: 'Kategori untuk makanan',
    createdAt: tDateTime,
  );

  group('GetCategories UseCase', () {
    test('should fetch categories list from the repository', () async {
      // Arrange
      repository.mockCategories = [tCategory];
      // Act
      final result = await getCategoriesUseCase(NoParams());
      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail: ${failure.message}'),
        (categories) => expect(categories, equals([tCategory])),
      );
      expect(repository.getCalled, isTrue);
    });
  });

  group('SaveCategory UseCase', () {
    test('should save category into the repository', () async {
      // Arrange
      repository.mockSavedId = 10;
      // Act
      final result = await saveCategoryUseCase(tCategory);
      // Assert
      expect(result, const Right(10));
      expect(repository.saveCalled, isTrue);
      expect(repository.mockCategories, contains(tCategory));
    });
  });

  group('DeleteCategory UseCase', () {
    test('should delete category from the repository', () async {
      // Arrange
      repository.mockCategories = [tCategory];
      // Act
      final result = await deleteCategoryUseCase(1);
      // Assert
      expect(result, const Right(null));
      expect(repository.deleteCalled, isTrue);
      expect(repository.deletedId, 1);
      expect(repository.mockCategories, isEmpty);
    });
  });
}
