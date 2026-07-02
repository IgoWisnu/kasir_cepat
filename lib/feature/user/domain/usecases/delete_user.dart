import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class DeleteUser implements UseCase<void, DeleteUserParams> {
  final UserRepository repository;

  DeleteUser(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserParams params) async {
    // 1. Check permissions: Only Owner can manage users
    if (params.currentUser.role != UserRole.owner) {
      return const Left(CacheFailure('Akses ditolak: Hanya Owner yang dapat mengelola pengguna.'));
    }

    // 2. Prevent self-deletion/deactivation to avoid lockout
    if (params.userIdToDelete == params.currentUser.id) {
      return const Left(CacheFailure('Akses ditolak: Anda tidak dapat menghapus atau menonaktifkan akun Anda sendiri.'));
    }

    // 3. Perform deletion/deactivation
    return await repository.deleteUser(params.userIdToDelete);
  }
}

class DeleteUserParams {
  final int userIdToDelete;
  final User currentUser;

  const DeleteUserParams({
    required this.userIdToDelete,
    required this.currentUser,
  });
}
