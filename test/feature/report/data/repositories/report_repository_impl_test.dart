import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/feature/report/data/datasources/report_local_datasource.dart';
import 'package:kasir_cepat/feature/report/data/repositories/report_repository_impl.dart';
import 'package:kasir_cepat/feature/report/domain/entities/sales_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/shift_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/stock_movement_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/product_selling_report.dart';

class FakeReportLocalDataSource implements ReportLocalDataSource {
  SalesReport? mockSalesReport;
  ShiftReport? mockShiftReport;
  List<StockMovementItem> mockMovements = [];
  bool shouldThrow = false;

  @override
  Future<SalesReport> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (shouldThrow) throw Exception('DB Error');
    return mockSalesReport!;
  }

  @override
  Future<ShiftReport> getShiftReport({
    required int shiftId,
  }) async {
    if (shouldThrow) throw Exception('DB Error');
    return mockShiftReport!;
  }

  @override
  Future<List<StockMovementItem>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (shouldThrow) throw Exception('DB Error');
    return mockMovements;
  }

  ProductSellingReport? mockProductSellingReport;

  @override
  Future<ProductSellingReport> getProductSellingReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (shouldThrow) throw Exception('DB Error');
    return mockProductSellingReport!;
  }
}

void main() {
  late FakeReportLocalDataSource localDataSource;
  late ReportRepositoryImpl repository;

  setUp(() {
    localDataSource = FakeReportLocalDataSource();
    repository = ReportRepositoryImpl(localDataSource);
  });

  final tStartDate = DateTime(2026, 6, 21);
  final tEndDate = DateTime(2026, 6, 21);

  final tSalesReport = SalesReport(
    startDate: tStartDate,
    endDate: tEndDate,
    totalSales: 500000.0,
    transactionCount: 20,
    totalCogs: 300000.0,
    totalDiscounts: 10000.0,
    grossProfit: 200000.0,
    categoryBreakdowns: const [],
    paymentBreakdowns: const [],
  );

  final tShiftReport = ShiftReport(
    shiftId: 1,
    startTime: tStartDate,
    endTime: tEndDate,
    status: 'closed',
    userId: 2,
    cashierName: 'Kasir Utama',
    cashStart: 100000.0,
    cashEnd: 250000.0,
    cashDifferent: 0.0,
    notes: 'Shift selesai',
    totalSales: 150000.0,
    transactionCount: 5,
    totalCogs: 90000.0,
    grossProfit: 60000.0,
    paymentBreakdowns: const [],
  );

  group('getSalesReport', () {
    test('should return SalesReport on success', () async {
      // Arrange
      localDataSource.mockSalesReport = tSalesReport;
      // Act
      final result = await repository.getSalesReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      expect(result, Right(tSalesReport));
    });

    test('should return CacheFailure on exception', () async {
      // Arrange
      localDataSource.shouldThrow = true;
      // Act
      final result = await repository.getSalesReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      expect(result, isA<Left<Failure, SalesReport>>());
    });
  });

  group('getShiftReport', () {
    test('should return ShiftReport on success', () async {
      // Arrange
      localDataSource.mockShiftReport = tShiftReport;
      // Act
      final result = await repository.getShiftReport(shiftId: 1);
      // Assert
      expect(result, Right(tShiftReport));
    });

    test('should return CacheFailure on exception', () async {
      // Arrange
      localDataSource.shouldThrow = true;
      // Act
      final result = await repository.getShiftReport(shiftId: 1);
      // Assert
      expect(result, isA<Left<Failure, ShiftReport>>());
    });
  });

  group('getStockMovementReport', () {
    test('should return movements list on success', () async {
      // Arrange
      localDataSource.mockMovements = [];
      // Act
      final result = await repository.getStockMovementReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      result.fold(
        (failure) => fail('Should not return failure'),
        (movements) => expect(movements, equals([])),
      );
    });

    test('should return CacheFailure on exception', () async {
      // Arrange
      localDataSource.shouldThrow = true;
      // Act
      final result = await repository.getStockMovementReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      expect(result, isA<Left<Failure, List<StockMovementItem>>>());
    });
  });

  group('getProductSellingReport', () {
    final tProductSellingReport = ProductSellingReport(
      startDate: tStartDate,
      endDate: tEndDate,
      items: const [
        ProductSellingItem(
          productId: 1,
          productName: 'Kopi Toraja',
          productSku: 'KOPI-01',
          quantitySold: 15.0,
          totalSales: 150000.0,
        ),
      ],
    );

    test('should return ProductSellingReport on success', () async {
      // Arrange
      localDataSource.mockProductSellingReport = tProductSellingReport;
      // Act
      final result = await repository.getProductSellingReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      expect(result, Right(tProductSellingReport));
    });

    test('should return CacheFailure on exception', () async {
      // Arrange
      localDataSource.shouldThrow = true;
      // Act
      final result = await repository.getProductSellingReport(startDate: tStartDate, endDate: tEndDate);
      // Assert
      expect(result, isA<Left<Failure, ProductSellingReport>>());
    });
  });
}
