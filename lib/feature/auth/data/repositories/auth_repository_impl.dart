import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../user/domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_with_pin.dart'; // import AuthFailure
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<User>>> getActiveCashiers() async {
    try {
      final models = await localDataSource.getActiveCashiers();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal memuat kasir: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithPin(User user, String pin) async {
    try {
      if (user.pin == pin) {
        return Right(user);
      } else {
        return const Left(AuthFailure('PIN yang Anda masukkan salah!'));
      }
    } catch (e) {
      return Left(CacheFailure('Gagal memverifikasi PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFirstTimePin(User user, String newPin) async {
    try {
      if (user.id == null) {
        return const Left(CacheFailure('ID User tidak valid'));
      }
      await localDataSource.updatePin(user.id!, newPin);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal memperbarui PIN: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> skipFirstTimePin(User user) async {
    try {
      if (user.id == null) {
        return const Left(CacheFailure('ID User tidak valid'));
      }
      await localDataSource.clearFirstLoginFlag(user.id!);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal memperbarui status login: $e'));
    }
  }
}
