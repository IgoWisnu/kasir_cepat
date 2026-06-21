import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_movement_report.dart';
import '../repositories/report_repository.dart';

class GetStockMovementReport implements UseCase<List<StockMovementItem>, GetStockMovementReportParams> {
  final ReportRepository repository;

  GetStockMovementReport(this.repository);

  @override
  Future<Either<Failure, List<StockMovementItem>>> call(GetStockMovementReportParams params) async {
    return await repository.getStockMovementReport(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetStockMovementReportParams {
  final DateTime startDate;
  final DateTime endDate;

  const GetStockMovementReportParams({
    required this.startDate,
    required this.endDate,
  });
}
