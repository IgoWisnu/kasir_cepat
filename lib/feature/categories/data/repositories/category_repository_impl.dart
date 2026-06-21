import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final models = await localDataSource.getCategories();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data kategori: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      final id = await localDataSource.saveCategory(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan data kategori: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await localDataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus data kategori: $e'));
    }
  }
}
