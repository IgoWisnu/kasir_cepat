import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class SaveUser implements UseCase<int, SaveUserParams> {
  final UserRepository repository;

  SaveUser(this.repository);

  @override
  Future<Either<Failure, int>> call(SaveUserParams params) async {
    // 1. Check permissions: Only Owner can manage users
    if (params.currentUser.role != UserRole.owner) {
      return const Left(CacheFailure('Akses ditolak: Hanya Owner yang dapat mengelola pengguna.'));
    }

    // 2. Enforce single-owner rule if the user being saved is an Owner
    if (params.user.role == UserRole.owner) {
      final ownerResult = await repository.getOwner();
      
      bool validationFailed = false;
      ownerResult.fold(
        (failure) {
          // If query fails, we block saving to be safe
          validationFailed = true;
        },
        (existingOwner) {
          if (existingOwner != null && existingOwner.id != params.user.id) {
            validationFailed = true;
          }
        },
      );

      if (validationFailed) {
        return const Left(CacheFailure('Akses ditolak: Hanya boleh ada satu Owner di sistem.'));
      }
    }

    // 3. Save the user
    return await repository.saveUser(params.user);
  }
}

class SaveUserParams {
  final User user;
  final User currentUser;

  const SaveUserParams({
    required this.user,
    required this.currentUser,
  });
}
