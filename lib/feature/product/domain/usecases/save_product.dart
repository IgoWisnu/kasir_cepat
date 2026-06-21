import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SaveProduct implements UseCase<int, Product> {
  final ProductRepository repository;

  SaveProduct(this.repository);

  @override
  Future<Either<Failure, int>> call(Product product) async {
    return await repository.saveProduct(product);
  }
}
