import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_local_datasource.dart';
import '../models/unit_model.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitLocalDataSource localDataSource;

  UnitRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Unit>>> getUnits() async {
    try {
      final models = await localDataSource.getUnits();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data satuan: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveUnit(Unit unit) async {
    try {
      final model = UnitModel.fromEntity(unit);
      final id = await localDataSource.saveUnit(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan data satuan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUnit(int id) async {
    try {
      await localDataSource.deleteUnit(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus data satuan: $e'));
    }
  }
}
