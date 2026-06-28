import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_cepat/feature/report/domain/entities/sales_report.dart';
import 'package:kasir_cepat/feature/report/presentation/provider/report_provider.dart';
import 'package:kasir_cepat/feature/report/presentation/report_dashboard_page.dart';

void main() {
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

  testWidgets('ReportDashboardPage renders stats and handles navigation', (WidgetTester tester) async {
    // Arrange
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ReportDashboardPage(),
        ),
        GoRoute(
          path: '/reports/sales',
          builder: (context, state) => const Scaffold(body: Text('Sales Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todaySalesReportProvider.overrideWith((ref) => tSalesReport),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Assert Today Overview Stats
    expect(find.text('Laporan Bisnis'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
    expect(find.text('Total Penjualan (Omset)'), findsOneWidget);
    expect(find.text('Rp 500.000'), findsOneWidget);
    expect(find.text('Laba Kotor'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);
    expect(find.text('Transaksi Sukses'), findsOneWidget);
    expect(find.text('20 Transaksi'), findsOneWidget);

    // Assert Navigation cards
    expect(find.text('Laporan Penjualan Detail'), findsOneWidget);
    expect(find.text('Laporan Penjualan Produk'), findsOneWidget);
    expect(find.text('Laporan Per Shift'), findsOneWidget);
    expect(find.text('Laporan Mutasi Stok'), findsOneWidget);

    // Act - click Laporan Penjualan
    await tester.tap(find.text('Laporan Penjualan Detail'));
    await tester.pumpAndSettle();

    // Assert navigated
    expect(find.text('Sales Page'), findsOneWidget);
  });
}
