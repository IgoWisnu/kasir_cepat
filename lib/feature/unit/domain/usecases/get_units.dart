import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/unit_entity.dart';
import '../repositories/unit_repository.dart';

class GetUnits implements UseCase<List<Unit>, NoParams> {
  final UnitRepository repository;

  GetUnits(this.repository);

  @override
  Future<Either<Failure, List<Unit>>> call(NoParams params) async {
    return await repository.getUnits();
  }
}
