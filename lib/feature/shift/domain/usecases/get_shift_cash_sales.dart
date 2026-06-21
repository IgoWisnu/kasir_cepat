import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/shift_repository.dart';

class GetShiftCashSales implements UseCase<double, int> {
  final ShiftRepository repository;

  GetShiftCashSales(this.repository);

  @override
  Future<Either<Failure, double>> call(int shiftId) async {
    return await repository.getShiftCashSales(shiftId);
  }
}
