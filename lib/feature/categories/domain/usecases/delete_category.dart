import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategory implements UseCase<void, int> {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteCategory(id);
  }
}
