import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    try {
      final models = await localDataSource.getUsers();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data user: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getUserById(int id) async {
    try {
      final model = await localDataSource.getUserById(id);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil user dengan id $id: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> saveUser(User user) async {
    try {
      final model = UserModel.fromEntity(user);
      final id = await localDataSource.saveUser(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan data user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      await localDataSource.deleteUser(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus data user: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getOwner() async {
    try {
      final model = await localDataSource.getOwner();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data owner: $e'));
    }
  }
}
