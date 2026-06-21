import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shift.dart';
import '../repositories/shift_repository.dart';

class GetShiftById implements UseCase<Shift?, GetShiftByIdParams> {
  final ShiftRepository repository;

  GetShiftById(this.repository);

  @override
  Future<Either<Failure, Shift?>> call(GetShiftByIdParams params) async {
    return await repository.getShiftById(params.id);
  }
}

class GetShiftByIdParams {
  final int id;

  const GetShiftByIdParams(this.id);
}
