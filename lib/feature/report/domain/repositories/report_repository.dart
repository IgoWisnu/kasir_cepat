import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sales_report.dart';
import '../entities/shift_report.dart';
import '../entities/stock_movement_report.dart';
import '../entities/product_selling_report.dart';

abstract class ReportRepository {
  Future<Either<Failure, SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, ShiftReport>> getShiftReport({
    required int shiftId,
  });

  Future<Either<Failure, List<StockMovementItem>>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, ProductSellingReport>> getProductSellingReport({
    required DateTime startDate,
    required DateTime endDate,
  });
}
