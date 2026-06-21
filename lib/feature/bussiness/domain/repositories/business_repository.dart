import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/business.dart';

abstract class BusinessRepository {
  /// Fetches the single local business profile.
  /// Returns `null` if no profile has been set up yet.
  Future<Either<Failure, Business?>> getBusiness();

  /// Saves (creates or updates) the business profile.
  /// Returns the ID of the saved business.
  Future<Either<Failure, int>> saveBusiness(Business business);

  /// Deletes the business profile with the specified ID.
  Future<Either<Failure, void>> deleteBusiness(int id);
}
