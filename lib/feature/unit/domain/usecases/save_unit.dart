import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/unit_entity.dart';
import '../repositories/unit_repository.dart';

class SaveUnit implements UseCase<int, Unit> {
  final UnitRepository repository;

  SaveUnit(this.repository);

  @override
  Future<Either<Failure, int>> call(Unit unit) async {
    return await repository.saveUnit(unit);
  }
}
