import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/discount.dart';
import '../../domain/repositories/discount_repository.dart';
import '../datasources/discount_local_datasource.dart';
import '../models/discount_model.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final DiscountLocalDataSource localDataSource;

  DiscountRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Discount>>> getDiscounts() async {
    try {
      final models = await localDataSource.getDiscounts();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data diskon: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveDiscount(Discount discount) async {
    try {
      final model = DiscountModel.fromEntity(discount);
      final id = await localDataSource.saveDiscount(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan data diskon: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDiscount(int id) async {
    try {
      await localDataSource.deleteDiscount(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus data diskon: $e'));
    }
  }
}
