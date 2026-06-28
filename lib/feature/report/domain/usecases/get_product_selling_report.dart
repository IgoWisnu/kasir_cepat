import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_selling_report.dart';
import '../repositories/report_repository.dart';

class GetProductSellingReport
    implements UseCase<ProductSellingReport, GetProductSellingReportParams> {
  final ReportRepository repository;

  GetProductSellingReport(this.repository);

  @override
  Future<Either<Failure, ProductSellingReport>> call(
    GetProductSellingReportParams params,
  ) async {
    return await repository.getProductSellingReport(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetProductSellingReportParams {
  final DateTime startDate;
  final DateTime endDate;

  const GetProductSellingReportParams({
    required this.startDate,
    required this.endDate,
  });
}
