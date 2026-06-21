import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class SaveCategory implements UseCase<int, Category> {
  final CategoryRepository repository;

  SaveCategory(this.repository);

  @override
  Future<Either<Failure, int>> call(Category category) async {
    return await repository.saveCategory(category);
  }
}
