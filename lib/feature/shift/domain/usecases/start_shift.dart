import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/shift_repository.dart';

class StartShift implements UseCase<int, StartShiftParams> {
  final ShiftRepository repository;

  StartShift(this.repository);

  @override
  Future<Either<Failure, int>> call(StartShiftParams params) async {
    return await repository.startShift(
      cashStart: params.cashStart,
      userId: params.userId,
      notes: params.notes,
    );
  }
}

class StartShiftParams {
  final double cashStart;
  final int? userId;
  final String? notes;

  const StartShiftParams({
    required this.cashStart,
    this.userId,
    this.notes,
  });
}
