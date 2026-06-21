import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/shift_repository.dart';

class CloseShift implements UseCase<void, CloseShiftParams> {
  final ShiftRepository repository;

  CloseShift(this.repository);

  @override
  Future<Either<Failure, void>> call(CloseShiftParams params) async {
    return await repository.closeShift(
      shiftId: params.shiftId,
      cashEnd: params.cashEnd,
      notes: params.notes,
    );
  }
}

class CloseShiftParams {
  final int shiftId;
  final double cashEnd;
  final String? notes;

  const CloseShiftParams({
    required this.shiftId,
    required this.cashEnd,
    this.notes,
  });
}
