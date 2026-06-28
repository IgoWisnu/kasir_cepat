import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../feature/auth/presentation/login_page.dart';
import '../../feature/auth/presentation/splash_page.dart';
import '../../feature/bussiness/presentation/business_profile_page.dart';
import '../../feature/bussiness/presentation/dashboard_page.dart';
import '../../feature/categories/presentation/category_list_page.dart';
import '../../feature/discount/presentation/discount_list_page.dart';
import '../../feature/unit/presentation/unit_list_page.dart';
import '../../feature/product/presentation/product_list_page.dart';
import '../../feature/product/presentation/product_form_page.dart';
import '../../feature/product/domain/entities/product.dart';
import '../../feature/stock/presentation/stock_list_page.dart';
import '../../feature/stock/presentation/restock_batch_page.dart';
import '../../feature/stock/presentation/opname_batch_page.dart';
import '../../feature/stock/presentation/stock_movement_page.dart';
import '../../feature/payment/presentation/payment_option_list_page.dart';
import '../../feature/pos/presentation/pos_page.dart';
import '../../feature/pos/presentation/payment_page.dart';
import '../../feature/printer/presentation/printer_list_page.dart';
import '../../feature/printer/presentation/receipt_template_page.dart';
import '../../feature/order/presentation/order_history_page.dart';
import '../../feature/shift/presentation/shift_history_page.dart';
import '../../feature/report/presentation/report_dashboard_page.dart';
import '../../feature/report/presentation/sales_report_page.dart';
import '../../feature/report/presentation/shift_report_page.dart';
import '../../feature/report/presentation/stock_movement_report_page.dart';
import '../../feature/report/presentation/product_selling_report_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Auth Cashier login route
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      // Dashboard menu route
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
      ),
      // Business Profile configuration route
      GoRoute(
        path: '/business-profile',
        builder: (context, state) => const BusinessProfilePage(),
      ),
      // Feature Skeletons / Placeholders
      GoRoute(
        path: '/pos',
        builder: (context, state) => const PosPage(),
      ),
      GoRoute(
        path: '/pos/payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/products/form',
        builder: (context, state) {
          final product = state.extra as Product?;
          return ProductFormPage(editingProduct: product);
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListPage(),
      ),
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitListPage(),
      ),
      GoRoute(
        path: '/stock',
        builder: (context, state) => const StockListPage(),
      ),
      GoRoute(
        path: '/stock/restock',
        builder: (context, state) => const RestockBatchPage(),
      ),
      GoRoute(
        path: '/stock/opname',
        builder: (context, state) => const OpnameBatchPage(),
      ),
      GoRoute(
        path: '/stock/movements',
        builder: (context, state) => const StockMovementPage(),
      ),
      GoRoute(
        path: '/discounts',
        builder: (context, state) => const DiscountListPage(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const PrinterListPage(),
      ),
      GoRoute(
        path: '/settings/receipt-template',
        builder: (context, state) => const ReceiptTemplatePage(),
      ),
      GoRoute(
        path: '/payment-options',
        builder: (context, state) => const PaymentOptionListPage(),
      ),
      GoRoute(
        path: '/shifts',
        builder: (context, state) => const ShiftHistoryPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportDashboardPage(),
      ),
      GoRoute(
        path: '/reports/sales',
        builder: (context, state) => const SalesReportPage(),
      ),
      GoRoute(
        path: '/reports/shifts',
        builder: (context, state) => const ShiftReportPage(),
      ),
      GoRoute(
        path: '/reports/stock-movements',
        builder: (context, state) => const StockMovementReportPage(),
      ),
      GoRoute(
        path: '/reports/product-selling',
        builder: (context, state) => const ProductSellingReportPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
}
