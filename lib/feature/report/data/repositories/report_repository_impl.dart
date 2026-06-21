import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/shift_report.dart';
import '../../domain/entities/stock_movement_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_local_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportLocalDataSource localDataSource;

  ReportRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final report = await localDataSource.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(report);
    } catch (e) {
      return Left(CacheFailure('Gagal memuat laporan penjualan: $e'));
    }
  }

  @override
  Future<Either<Failure, ShiftReport>> getShiftReport({
    required int shiftId,
  }) async {
    try {
      final report = await localDataSource.getShiftReport(shiftId: shiftId);
      return Right(report);
    } catch (e) {
      return Left(CacheFailure('Gagal memuat laporan shift: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StockMovementItem>>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final movements = await localDataSource.getStockMovementReport(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(movements);
    } catch (e) {
      return Left(CacheFailure('Gagal memuat laporan mutasi stok: $e'));
    }
  }
}
