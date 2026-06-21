import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/unit_repository.dart';

class DeleteUnit implements UseCase<void, int> {
  final UnitRepository repository;

  DeleteUnit(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteUnit(id);
  }
}
