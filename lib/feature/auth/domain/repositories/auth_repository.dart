import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../user/domain/entities/user.dart';

abstract class AuthRepository {
  /// Fetches all active cashiers for selection on login screen.
  Future<Either<Failure, List<User>>> getActiveCashiers();

  /// Logs in a user with a PIN.
  Future<Either<Failure, User>> loginWithPin(User user, String pin);

  /// Saves new PIN and marks first time login as completed.
  Future<Either<Failure, void>> updateFirstTimePin(User user, String newPin);

  /// Skips changing the PIN but marks first time login as completed.
  Future<Either<Failure, void>> skipFirstTimePin(User user);
}
