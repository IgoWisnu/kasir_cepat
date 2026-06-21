import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts({int? categoryId}) async {
    try {
      final models = await localDataSource.getProducts(categoryId: categoryId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data produk: $e'));
    }
  }

  @override
  Future<Either<Failure, Product?>> getProductById(int id) async {
    try {
      final model = await localDataSource.getProductById(id);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil produk dengan id $id: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);
      final id = await localDataSource.saveProduct(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan data produk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await localDataSource.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus data produk: $e'));
    }
  }
}
