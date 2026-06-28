import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../shift/domain/entities/shift.dart';
import '../../../shift/presentation/provider/shift_provider.dart';
import '../../data/datasources/report_local_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/shift_report.dart';
import '../../domain/entities/stock_movement_report.dart';
import '../../domain/entities/product_selling_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/get_sales_report.dart';
import '../../domain/usecases/get_shift_report.dart';
import '../../domain/usecases/get_stock_movement_report.dart';
import '../../domain/usecases/get_product_selling_report.dart';

// Providers for repository and data sources
final reportLocalDataSourceProvider = Provider<ReportLocalDataSource>((ref) {
  return ReportLocalDataSourceImpl(DatabaseHelper.instance);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.read(reportLocalDataSourceProvider));
});

// Providers for usecases
final getSalesReportUseCaseProvider = Provider<GetSalesReport>((ref) {
  return GetSalesReport(ref.read(reportRepositoryProvider));
});

final getShiftReportUseCaseProvider = Provider<GetShiftReport>((ref) {
  return GetShiftReport(ref.read(reportRepositoryProvider));
});

final getStockMovementReportUseCaseProvider = Provider<GetStockMovementReport>((ref) {
  return GetStockMovementReport(ref.read(reportRepositoryProvider));
});

final getProductSellingReportUseCaseProvider = Provider<GetProductSellingReport>((ref) {
  return GetProductSellingReport(ref.read(reportRepositoryProvider));
});

// UI State and Data Providers

// 1. Sales Report
final salesReportDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
  );
});

final salesReportProvider = FutureProvider.autoDispose<SalesReport>((ref) async {
  final range = ref.watch(salesReportDateRangeProvider);
  final getSalesReport = ref.read(getSalesReportUseCaseProvider);
  
  final result = await getSalesReport(GetSalesReportParams(
    startDate: range.start,
    endDate: range.end,
  ));
  
  return result.fold(
    (failure) => throw failure.message,
    (report) => report,
  );
});

final todaySalesReportProvider = FutureProvider.autoDispose<SalesReport>((ref) async {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, now.day);
  final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  
  final getSalesReport = ref.read(getSalesReportUseCaseProvider);
  final result = await getSalesReport(GetSalesReportParams(
    startDate: startDate,
    endDate: endDate,
  ));
  
  return result.fold(
    (failure) => throw failure.message,
    (report) => report,
  );
});

// 2. Stock Movement Report
final reportStockMovementDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
  );
});

final reportStockMovementReportProvider = FutureProvider.autoDispose<List<StockMovementItem>>((ref) async {
  final range = ref.watch(reportStockMovementDateRangeProvider);
  final getStockMovementReport = ref.read(getStockMovementReportUseCaseProvider);
  
  final result = await getStockMovementReport(GetStockMovementReportParams(
    startDate: range.start,
    endDate: range.end,
  ));
  
  return result.fold(
    (failure) => throw failure.message,
    (movements) => movements,
  );
});

// 3. Shift Selector & Shift Report
final selectedShiftIdProvider = StateProvider<int?>((ref) => null);

final reportShiftsListProvider = FutureProvider.autoDispose<List<Shift>>((ref) async {
  final getShifts = ref.read(getShiftsUseCaseProvider);
  final result = await getShifts(NoParams());
  return result.fold(
    (failure) => throw failure.message,
    (shifts) => shifts,
  );
});

final shiftReportProvider = FutureProvider.autoDispose.family<ShiftReport, int>((ref, shiftId) async {
  final getShiftReport = ref.read(getShiftReportUseCaseProvider);
  final result = await getShiftReport(shiftId);
  return result.fold(
    (failure) => throw failure.message,
    (report) => report,
  );
});

// 4. Product Selling Report
final productSellingDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
  );
});

final productSellingReportProvider = FutureProvider.autoDispose<ProductSellingReport>((ref) async {
  final range = ref.watch(productSellingDateRangeProvider);
  final getProductSellingReport = ref.read(getProductSellingReportUseCaseProvider);
  
  final result = await getProductSellingReport(GetProductSellingReportParams(
    startDate: range.start,
    endDate: range.end,
  ));
  
  return result.fold(
    (failure) => throw failure.message,
    (report) => report,
  );
});
