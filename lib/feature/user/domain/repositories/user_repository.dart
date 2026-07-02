import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  /// Fetches all active/inactive users.
  Future<Either<Failure, List<User>>> getUsers();

  /// Fetches a specific user by ID.
  Future<Either<Failure, User?>> getUserById(int id);

  /// Saves (creates or updates) a user.
  /// Returns the ID of the saved user.
  Future<Either<Failure, int>> saveUser(User user);

  /// Deletes or deactivates the user with the specified ID.
  Future<Either<Failure, void>> deleteUser(int id);

  /// Helper to fetch the current Owner if one exists (for enforcing single-owner rule).
  Future<Either<Failure, User?>> getOwner();
}
