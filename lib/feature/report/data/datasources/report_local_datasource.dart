import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/shift_report.dart';
import '../../domain/entities/stock_movement_report.dart';

abstract class ReportLocalDataSource {
  Future<SalesReport> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<ShiftReport> getShiftReport({
    required int shiftId,
  });

  Future<List<StockMovementItem>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class ReportLocalDataSourceImpl implements ReportLocalDataSource {
  final DatabaseHelper databaseHelper;

  ReportLocalDataSourceImpl(this.databaseHelper);

  String _formatDateStart(DateTime date) {
    return '${DateFormat('yyyy-MM-dd').format(date)}T00:00:00.000';
  }

  String _formatDateEnd(DateTime date) {
    return '${DateFormat('yyyy-MM-dd').format(date)}T23:59:59.999';
  }

  @override
  Future<SalesReport> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await databaseHelper.database;
    final startStr = _formatDateStart(startDate);
    final endStr = _formatDateEnd(endDate);

    // 1. Total Sales, Transactions, Discounts
    final salesRes = await db.rawQuery('''
      SELECT 
        COUNT(id) as transaction_count,
        SUM(grand_total) as total_sales,
        SUM(discount_value) as total_discounts
      FROM orders
      WHERE order_status = 'completed' AND created_at >= ? AND created_at <= ?
    ''', [startStr, endStr]);

    final transactionCount = salesRes.first['transaction_count'] as int? ?? 0;
    final totalSales = (salesRes.first['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalDiscounts = (salesRes.first['total_discounts'] as num?)?.toDouble() ?? 0.0;

    // 2. COGS
    final cogsRes = await db.rawQuery('''
      SELECT SUM(oi.cost_price * oi.qty) as total_cogs
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.order_status = 'completed' AND o.created_at >= ? AND o.created_at <= ?
    ''', [startStr, endStr]);

    final totalCogs = (cogsRes.first['total_cogs'] as num?)?.toDouble() ?? 0.0;
    final grossProfit = totalSales - totalCogs;

    // 3. Category Breakdown
    final catRes = await db.rawQuery('''
      SELECT 
        COALESCE(c.name, 'Tanpa Kategori') as category_name,
        SUM(oi.qty) as quantity_sold,
        SUM(oi.subtotal) as total_sales
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      LEFT JOIN products p ON oi.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE o.order_status = 'completed' AND o.created_at >= ? AND o.created_at <= ?
      GROUP BY c.id, c.name
      ORDER BY total_sales DESC
    ''', [startStr, endStr]);

    final categoryBreakdowns = catRes.map((row) {
      return CategoryBreakdown(
        categoryName: row['category_name'] as String,
        quantitySold: (row['quantity_sold'] as num?)?.toDouble() ?? 0.0,
        totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    // 4. Payment Breakdown
    final payRes = await db.rawQuery('''
      SELECT 
        COALESCE(po.name, 'Tunai') as payment_name,
        COUNT(o.id) as transaction_count,
        SUM(o.grand_total) as total_sales
      FROM orders o
      LEFT JOIN payment_options po ON o.payment_option_id = po.id
      WHERE o.order_status = 'completed' AND o.created_at >= ? AND o.created_at <= ?
      GROUP BY o.payment_option_id, po.name
      ORDER BY total_sales DESC
    ''', [startStr, endStr]);

    final paymentBreakdowns = payRes.map((row) {
      return PaymentBreakdown(
        paymentName: row['payment_name'] as String,
        transactionCount: row['transaction_count'] as int? ?? 0,
        totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return SalesReport(
      startDate: startDate,
      endDate: endDate,
      totalSales: totalSales,
      transactionCount: transactionCount,
      totalCogs: totalCogs,
      totalDiscounts: totalDiscounts,
      grossProfit: grossProfit,
      categoryBreakdowns: categoryBreakdowns,
      paymentBreakdowns: paymentBreakdowns,
    );
  }

  @override
  Future<ShiftReport> getShiftReport({
    required int shiftId,
  }) async {
    final db = await databaseHelper.database;

    // 1. Shift Metadata + Cashier Name
    final shiftRes = await db.rawQuery('''
      SELECT 
        s.*,
        u.name as cashier_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.id = ?
    ''', [shiftId]);

    if (shiftRes.isEmpty) {
      throw Exception('Shift tidak ditemukan');
    }

    final row = shiftRes.first;
    final startTime = DateTime.parse(row['start_time'] as String);
    final endTime = row['end_time'] != null ? DateTime.parse(row['end_time'] as String) : null;
    final status = row['status'] as String;
    final userId = row['user_id'] as int?;
    final cashierName = row['cashier_name'] as String? ?? 'Kasir #${userId ?? ""}';
    final cashStart = (row['cash_start'] as num).toDouble();
    final cashEnd = row['cash_end'] != null ? (row['cash_end'] as num).toDouble() : null;
    final cashDifferent = row['cash_different'] != null ? (row['cash_different'] as num).toDouble() : null;
    final notes = row['notes'] as String?;

    // 2. Sales Summary (Total Sales & Transaction Count)
    final salesRes = await db.rawQuery('''
      SELECT 
        COUNT(id) as transaction_count,
        SUM(grand_total) as total_sales
      FROM orders
      WHERE shift_id = ? AND order_status = 'completed'
    ''', [shiftId]);

    final transactionCount = salesRes.first['transaction_count'] as int? ?? 0;
    final totalSales = (salesRes.first['total_sales'] as num?)?.toDouble() ?? 0.0;

    // 3. COGS
    final cogsRes = await db.rawQuery('''
      SELECT SUM(oi.cost_price * oi.qty) as total_cogs
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.shift_id = ? AND o.order_status = 'completed'
    ''', [shiftId]);

    final totalCogs = (cogsRes.first['total_cogs'] as num?)?.toDouble() ?? 0.0;
    final grossProfit = totalSales - totalCogs;

    // 4. Payment Option Breakdown
    final payRes = await db.rawQuery('''
      SELECT 
        COALESCE(po.name, 'Tunai') as payment_name,
        COUNT(o.id) as transaction_count,
        SUM(o.grand_total) as total_sales
      FROM orders o
      LEFT JOIN payment_options po ON o.payment_option_id = po.id
      WHERE o.shift_id = ? AND o.order_status = 'completed'
      GROUP BY o.payment_option_id, po.name
      ORDER BY total_sales DESC
    ''', [shiftId]);

    final paymentBreakdowns = payRes.map((row) {
      return PaymentBreakdown(
        paymentName: row['payment_name'] as String,
        transactionCount: row['transaction_count'] as int? ?? 0,
        totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return ShiftReport(
      shiftId: shiftId,
      startTime: startTime,
      endTime: endTime,
      status: status,
      userId: userId,
      cashierName: cashierName,
      cashStart: cashStart,
      cashEnd: cashEnd,
      cashDifferent: cashDifferent,
      notes: notes,
      totalSales: totalSales,
      transactionCount: transactionCount,
      totalCogs: totalCogs,
      grossProfit: grossProfit,
      paymentBreakdowns: paymentBreakdowns,
    );
  }

  @override
  Future<List<StockMovementItem>> getStockMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await databaseHelper.database;
    final startStr = _formatDateStart(startDate);
    final endStr = _formatDateEnd(endDate);

    final results = await db.rawQuery('''
      SELECT 
        st.*,
        COALESCE(p.name, 'Produk Terhapus') as product_name,
        COALESCE(p.sku, 'SKU-NONE') as product_sku
      FROM stock_transactions st
      LEFT JOIN products p ON st.product_id = p.id
      WHERE st.created_at >= ? AND st.created_at <= ?
      ORDER BY st.created_at DESC
    ''', [startStr, endStr]);

    return results.map((row) {
      return StockMovementItem(
        id: row['id'] as int,
        productId: row['product_id'] as int?,
        productName: row['product_name'] as String,
        productSku: row['product_sku'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        type: row['type'] as String,
        reference: row['reference'] as String?,
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }
}
