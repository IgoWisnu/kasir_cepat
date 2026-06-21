import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sales_report.dart';
import '../repositories/report_repository.dart';

class GetSalesReport implements UseCase<SalesReport, GetSalesReportParams> {
  final ReportRepository repository;

  GetSalesReport(this.repository);

  @override
  Future<Either<Failure, SalesReport>> call(GetSalesReportParams params) async {
    return await repository.getSalesReport(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetSalesReportParams {
  final DateTime startDate;
  final DateTime endDate;

  const GetSalesReportParams({
    required this.startDate,
    required this.endDate,
  });
}
