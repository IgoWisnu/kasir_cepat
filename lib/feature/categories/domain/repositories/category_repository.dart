import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  /// Fetches all stored product categories.
  Future<Either<Failure, List<Category>>> getCategories();

  /// Saves (creates or updates) a product category.
  /// Returns the ID of the saved category.
  Future<Either<Failure, int>> saveCategory(Category category);

  /// Deletes the product category with the specified ID.
  Future<Either<Failure, void>> deleteCategory(int id);
}
