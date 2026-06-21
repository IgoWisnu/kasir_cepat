import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  /// Fetches all products, optionally filtered by category.
  Future<Either<Failure, List<Product>>> getProducts({int? categoryId});

  /// Fetches a specific product by its ID.
  Future<Either<Failure, Product?>> getProductById(int id);

  /// Saves (creates or updates) a product.
  /// Returns the ID of the saved product.
  Future<Either<Failure, int>> saveProduct(Product product);

  /// Deletes the product with the specified ID.
  Future<Either<Failure, void>> deleteProduct(int id);
}
