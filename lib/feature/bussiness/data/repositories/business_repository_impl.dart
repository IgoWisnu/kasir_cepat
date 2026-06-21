import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_local_datasource.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessLocalDataSource localDataSource;

  BusinessRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Business?>> getBusiness() async {
    try {
      final businessModel = await localDataSource.getBusiness();
      if (businessModel == null) {
        return const Right(null);
      }
      return Right(businessModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal memuat profil bisnis dari database lokal: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveBusiness(Business business) async {
    try {
      final model = BusinessModel.fromEntity(business);
      final id = await localDataSource.saveBusiness(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan profil bisnis ke database lokal: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBusiness(int id) async {
    try {
      await localDataSource.deleteBusiness(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus profil bisnis dari database lokal: $e'));
    }
  }
}
