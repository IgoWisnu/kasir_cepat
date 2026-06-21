import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shift_report.dart';
import '../repositories/report_repository.dart';

class GetShiftReport implements UseCase<ShiftReport, int> {
  final ReportRepository repository;

  GetShiftReport(this.repository);

  @override
  Future<Either<Failure, ShiftReport>> call(int shiftId) async {
    return await repository.getShiftReport(shiftId: shiftId);
  }
}
