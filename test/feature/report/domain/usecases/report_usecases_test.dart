import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/feature/report/domain/entities/sales_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/shift_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/stock_movement_report.dart';
import 'package:kasir_cepat/feature/report/domain/repositories/report_repository.dart';
import 'package:kasir_cepat/feature/report/domain/usecases/get_sales_report.dart';
import 'package:kasir_cepat/feature/report/domain/usecases/get_shift_report.dart';
import 'package:kasir_cepat/feature/report/domain/usecases/get_stock_movement_report.dart';
import 'package:kasir_cepat/feature/report/domain/entities/product_selling_report.dart';
import 'package:kasir_cepat/feature/report/domain/usecases/get_product_selling_report.dart';

class FakeReportRepository implements ReportRepository {
  SalesReport? mockSalesReport;
  ShiftReport? mockShiftReport;
  List<StockMovementItem> mockMovements = [];

  bool getSalesReportCalled = false;
  bool getShiftReportCalled = false;
  bool getStockMovementReportCalled = false;

  DateTime? lastStartDate;
  DateTime? lastEndDate;
  int? lastShiftId;

  @override
  Future<Either<Failure, SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    getSalesReportCalled = true;
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (mockSalesReport == null) {
      return Left(CacheFailure('Laporan tidak ada'));
    }
    return Right(mockSalesReport!);
  }

  @override
  Future<Either<Failure, ShiftReport>> getShiftReport({
    required int shiftId,
  }) async {
    getShiftReportCalled = true;
    lastShiftId = shiftId;
    if (mockShiftReport == null) {
      return Left(CacheFailure('Laporan tidak ada'));
    }
    return Right(mockShiftReport!);
  }

  @override
  Future<Either<Failure, List<StockMovementItem>>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    getStockMovementReportCalled = true;
    lastStartDate = startDate;
    lastEndDate = endDate;
    return Right(mockMovements);
  }

  ProductSellingReport? mockProductSellingReport;
  bool getProductSellingReportCalled = false;

  @override
  Future<Either<Failure, ProductSellingReport>> getProductSellingReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    getProductSellingReportCalled = true;
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (mockProductSellingReport == null) {
      return Left(CacheFailure('Laporan tidak ada'));
    }
    return Right(mockProductSellingReport!);
  }
}

void main() {
  late FakeReportRepository repository;
  late GetSalesReport getSalesReportUseCase;
  late GetShiftReport getShiftReportUseCase;
  late GetStockMovementReport getStockMovementReportUseCase;
  late GetProductSellingReport getProductSellingReportUseCase;

  setUp(() {
    repository = FakeReportRepository();
    getSalesReportUseCase = GetSalesReport(repository);
    getShiftReportUseCase = GetShiftReport(repository);
    getStockMovementReportUseCase = GetStockMovementReport(repository);
    getProductSellingReportUseCase = GetProductSellingReport(repository);
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
    categoryBreakdowns: const [
      CategoryBreakdown(categoryName: 'Makanan', quantitySold: 10, totalSales: 150000.0),
    ],
    paymentBreakdowns: const [
      PaymentBreakdown(paymentName: 'Tunai', transactionCount: 15, totalSales: 400000.0),
    ],
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
    paymentBreakdowns: const [
      PaymentBreakdown(paymentName: 'Tunai', transactionCount: 5, totalSales: 150000.0),
    ],
  );

  final tMovementItem = StockMovementItem(
    id: 1,
    productId: 10,
    productName: 'Kopi Toraja',
    productSku: 'KOPI-01',
    quantity: 5.0,
    type: 'sale',
    reference: 'INV-100',
    notes: 'Penjualan POS',
    createdAt: tStartDate,
  );

  group('GetSalesReport UseCase', () {
    test('should fetch sales report from the repository', () async {
      // Arrange
      repository.mockSalesReport = tSalesReport;
      // Act
      final result = await getSalesReportUseCase(
        GetSalesReportParams(startDate: tStartDate, endDate: tEndDate),
      );
      // Assert
      expect(result, Right(tSalesReport));
      expect(repository.getSalesReportCalled, isTrue);
      expect(repository.lastStartDate, tStartDate);
      expect(repository.lastEndDate, tEndDate);
    });
  });

  group('GetShiftReport UseCase', () {
    test('should fetch shift report from the repository', () async {
      // Arrange
      repository.mockShiftReport = tShiftReport;
      // Act
      final result = await getShiftReportUseCase(1);
      // Assert
      expect(result, Right(tShiftReport));
      expect(repository.getShiftReportCalled, isTrue);
      expect(repository.lastShiftId, 1);
    });
  });

  group('GetStockMovementReport UseCase', () {
    test('should fetch stock movements from the repository', () async {
      // Arrange
      repository.mockMovements = [tMovementItem];
      // Act
      final result = await getStockMovementReportUseCase(
        GetStockMovementReportParams(startDate: tStartDate, endDate: tEndDate),
      );
      // Assert
      result.fold(
        (failure) => fail('Should not return failure'),
        (movements) => expect(movements, equals([tMovementItem])),
      );
      expect(repository.getStockMovementReportCalled, isTrue);
      expect(repository.lastStartDate, tStartDate);
      expect(repository.lastEndDate, tEndDate);
    });
  });

  group('GetProductSellingReport UseCase', () {
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

    test('should fetch product selling report from the repository', () async {
      // Arrange
      repository.mockProductSellingReport = tProductSellingReport;
      // Act
      final result = await getProductSellingReportUseCase(
        GetProductSellingReportParams(startDate: tStartDate, endDate: tEndDate),
      );
      // Assert
      expect(result, Right(tProductSellingReport));
      expect(repository.getProductSellingReportCalled, isTrue);
      expect(repository.lastStartDate, tStartDate);
      expect(repository.lastEndDate, tEndDate);
    });
  });
}
