import 'package:equatable/equatable.dart';

class CategoryBreakdown extends Equatable {
  final String categoryName;
  final double quantitySold;
  final double totalSales;

  const CategoryBreakdown({
    required this.categoryName,
    required this.quantitySold,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [categoryName, quantitySold, totalSales];
}

class PaymentBreakdown extends Equatable {
  final String paymentName;
  final int transactionCount;
  final double totalSales;

  const PaymentBreakdown({
    required this.paymentName,
    required this.transactionCount,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [paymentName, transactionCount, totalSales];
}

class SalesReport extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final int transactionCount;
  final double totalCogs;
  final double totalDiscounts;
  final double grossProfit;
  final List<CategoryBreakdown> categoryBreakdowns;
  final List<PaymentBreakdown> paymentBreakdowns;

  const SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.transactionCount,
    required this.totalCogs,
    required this.totalDiscounts,
    required this.grossProfit,
    required this.categoryBreakdowns,
    required this.paymentBreakdowns,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalSales,
        transactionCount,
        totalCogs,
        totalDiscounts,
        grossProfit,
        categoryBreakdowns,
        paymentBreakdowns,
      ];
}
