import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/discount.dart';

abstract class DiscountRepository {
  /// Fetches all stored discounts.
  Future<Either<Failure, List<Discount>>> getDiscounts();

  /// Saves (creates or updates) a discount.
  /// Returns the ID of the saved discount.
  Future<Either<Failure, int>> saveDiscount(Discount discount);

  /// Deletes the discount with the specified ID.
  Future<Either<Failure, void>> deleteDiscount(int id);
}
