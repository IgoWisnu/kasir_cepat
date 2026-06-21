import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shift.dart';
import '../repositories/shift_repository.dart';

class GetActiveShift implements UseCase<Shift?, NoParams> {
  final ShiftRepository repository;

  GetActiveShift(this.repository);

  @override
  Future<Either<Failure, Shift?>> call(NoParams params) async {
    return await repository.getActiveShift();
  }
}
