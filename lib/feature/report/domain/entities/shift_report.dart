import 'package:equatable/equatable.dart';
import 'sales_report.dart';

class ShiftReport extends Equatable {
  final int shiftId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'open', 'closed'
  final int? userId;
  final String cashierName;
  final double cashStart;
  final double? cashEnd;
  final double? cashDifferent;
  final String? notes;
  // Sales summary for this shift
  final double totalSales;
  final int transactionCount;
  final double totalCogs;
  final double grossProfit;
  final List<PaymentBreakdown> paymentBreakdowns;

  const ShiftReport({
    required this.shiftId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.userId,
    required this.cashierName,
    required this.cashStart,
    this.cashEnd,
    this.cashDifferent,
    this.notes,
    required this.totalSales,
    required this.transactionCount,
    required this.totalCogs,
    required this.grossProfit,
    required this.paymentBreakdowns,
  });

  @override
  List<Object?> get props => [
        shiftId,
        startTime,
        endTime,
        status,
        userId,
        cashierName,
        cashStart,
        cashEnd,
        cashDifferent,
        notes,
        totalSales,
        transactionCount,
        totalCogs,
        grossProfit,
        paymentBreakdowns,
      ];
}
