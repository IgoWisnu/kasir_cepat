import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shift.dart';
import '../repositories/shift_repository.dart';

class GetShifts implements UseCase<List<Shift>, NoParams> {
  final ShiftRepository repository;

  GetShifts(this.repository);

  @override
  Future<Either<Failure, List<Shift>>> call(NoParams params) async {
    return await repository.getShifts();
  }
}
