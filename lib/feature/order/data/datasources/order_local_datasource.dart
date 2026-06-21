import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/order.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';

abstract class OrderLocalDataSource {
  Future<int> createPendingOrder(OrderModel order);
  Future<void> updateOrder(OrderModel order);
  Future<void> payOrder({
    required int orderId,
    required int paymentOptionId,
    required double cashReceived,
    required double changeGiven,
  });
  Future<OrderModel?> getOrderById(int id);
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
  });
  Future<void> cancelOrder(int orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final DatabaseHelper databaseHelper;

  OrderLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<int> createPendingOrder(OrderModel order) async {
    final db = await databaseHelper.database;
    int orderId = 0;

    await db.transaction((txn) async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // 1. Calculate Daily Queue Number
      final queueResults = await txn.rawQuery(
        'SELECT MAX(order_queue) as max_queue FROM orders WHERE created_at >= ? AND created_at <= ?',
        [todayStart, todayEnd],
      );
      final maxQueue = (queueResults.first['max_queue'] as int?) ?? 0;
      final nextQueue = maxQueue + 1;

      // 2. Insert Order Header
      final finalOrder = order.copyWith(
        orderQueue: nextQueue,
        orderStatus: OrderStatus.newOrder,
        paymentStatus: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      orderId = await txn.insert('orders', OrderModel.fromEntity(finalOrder).toMap());

      // 3. Insert Order Items & Deduct Stock
      for (final item in order.items) {
        // Create model
        final itemModel = OrderItemModel.fromEntity(item).copyWith(
          orderId: orderId,
          createdAt: now,
        );

        await txn.insert('order_items', itemModel.toMap());

        // Deduct Stock immediately
        if (item.productId != null) {
          final products = await txn.query(
            'products',
            columns: ['is_track_stock', 'stock_quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
            limit: 1,
          );

          if (products.isNotEmpty) {
            final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
            if (isTrackStock) {
              final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
              final newStock = currentStock - item.qty;

              // Update stock
              await txn.update(
                'products',
                {'stock_quantity': newStock},
                where: 'id = ?',
                whereArgs: [item.productId],
              );

              // Log stock transaction
              await txn.insert('stock_transactions', {
                'product_id': item.productId,
                'quantity': -item.qty, // negative for sale
                'type': 'sale',
                'reference': 'ORDER-$orderId',
                'notes': 'Pengurangan stok pesanan baru #$nextQueue',
                'created_at': now.toIso8601String(),
              });
            }
          }
        }
      }
    });

    return orderId;
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    final db = await databaseHelper.database;
    final orderId = order.id;
    if (orderId == null) {
      throw Exception('ID pesanan tidak boleh kosong untuk pembaruan');
    }

    await db.transaction((txn) async {
      final now = DateTime.now();

      // 1. Fetch old items from DB to revert stock
      final oldItemsResults = await txn.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final oldItems = oldItemsResults.map((map) => OrderItemModel.fromMap(map)).toList();

      // 2. Revert stock of old items
      for (final oldItem in oldItems) {
        if (oldItem.productId != null) {
          final products = await txn.query(
            'products',
            columns: ['is_track_stock', 'stock_quantity'],
            where: 'id = ?',
            whereArgs: [oldItem.productId],
            limit: 1,
          );

          if (products.isNotEmpty) {
            final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
            if (isTrackStock) {
              final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
              final revertedStock = currentStock + oldItem.qty;

              await txn.update(
                'products',
                {'stock_quantity': revertedStock},
                where: 'id = ?',
                whereArgs: [oldItem.productId],
              );

              // Log reversion transaction
              await txn.insert('stock_transactions', {
                'product_id': oldItem.productId,
                'quantity': oldItem.qty,
                'type': 'stock_in',
                'reference': 'ORDER-UPDATE-REVERT-$orderId',
                'notes': 'Pengembalian stok koreksi pesanan',
                'created_at': now.toIso8601String(),
              });
            }
          }
        }
      }

      // 3. Delete old items
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      // 4. Insert new items and deduct stock
      for (final item in order.items) {
        final itemModel = OrderItemModel.fromEntity(item).copyWith(
          orderId: orderId,
          createdAt: now,
        );

        await txn.insert('order_items', itemModel.toMap());

        // Deduct new stock
        if (item.productId != null) {
          final products = await txn.query(
            'products',
            columns: ['is_track_stock', 'stock_quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
            limit: 1,
          );

          if (products.isNotEmpty) {
            final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
            if (isTrackStock) {
              final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
              final newStock = currentStock - item.qty;

              await txn.update(
                'products',
                {'stock_quantity': newStock},
                where: 'id = ?',
                whereArgs: [item.productId],
              );

              // Log deduction transaction
              await txn.insert('stock_transactions', {
                'product_id': item.productId,
                'quantity': -item.qty,
                'type': 'sale',
                'reference': 'ORDER-UPDATE-APPLY-$orderId',
                'notes': 'Pengurangan stok koreksi pesanan',
                'created_at': now.toIso8601String(),
              });
            }
          }
        }
      }

      // 5. Update Order Header
      final finalOrder = order.copyWith(
        updatedAt: now,
      );

      await txn.update(
        'orders',
        OrderModel.fromEntity(finalOrder).toMap(),
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  @override
  Future<void> payOrder({
    required int orderId,
    required int paymentOptionId,
    required double cashReceived,
    required double changeGiven,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      final now = DateTime.now();

      // 1. Fetch Order Details
      final orderResults = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderResults.isEmpty) {
        throw Exception('Pesanan dengan ID $orderId tidak ditemukan');
      }

      final orderMap = orderResults.first;
      final existingInvoiceNumber = orderMap['invoice_number'] as String?;
      final grandTotal = (orderMap['grand_total'] as num).toDouble();

      String finalInvoiceNumber = existingInvoiceNumber ?? '';

      // 2. Generate Invoice Number if empty
      if (finalInvoiceNumber.isEmpty) {
        final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

        final invoiceCountResults = await txn.rawQuery(
          "SELECT COUNT(*) as count FROM orders WHERE invoice_number IS NOT NULL AND created_at >= ? AND created_at <= ?",
          [todayStart, todayEnd],
        );
        final count = (invoiceCountResults.first['count'] as int?) ?? 0;
        final nextInvoiceNum = count + 1;

        final dateStr = DateFormat('yyyyMMdd').format(now);
        final paddedNum = nextInvoiceNum.toString().padLeft(4, '0');
        finalInvoiceNumber = 'INV/$dateStr/$paddedNum';
      }

      // 3. Update Order to Completed/Paid
      await txn.update(
        'orders',
        {
          'invoice_number': finalInvoiceNumber,
          'order_status': OrderStatus.completed.toDbString,
          'payment_status': PaymentStatus.paid.toDbString,
          'payment_option_id': paymentOptionId,
          'cash_received': cashReceived,
          'change_given': changeGiven,
          'paid_amount': grandTotal,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  @override
  Future<OrderModel?> getOrderById(int id) async {
    final db = await databaseHelper.database;

    // 1. Get Order Header
    final headerResults = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (headerResults.isEmpty) return null;

    // 2. Get Order Items
    final itemResults = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );

    final items = itemResults.map((map) => OrderItemModel.fromMap(map)).toList();

    return OrderModel.fromMap(headerResults.first, items: items);
  }

  @override
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
  }) async {
    final db = await databaseHelper.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (status != null && paymentStatus != null) {
      whereClause = 'order_status = ? AND payment_status = ?';
      whereArgs = [status.toDbString, paymentStatus.toDbString];
    } else if (status != null) {
      whereClause = 'order_status = ?';
      whereArgs = [status.toDbString];
    } else if (paymentStatus != null) {
      whereClause = 'payment_status = ?';
      whereArgs = [paymentStatus.toDbString];
    }

    final headerResults = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<OrderModel> orders = [];

    for (final headerMap in headerResults) {
      final orderId = headerMap['id'] as int;

      final itemResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final items = itemResults.map((map) => OrderItemModel.fromMap(map)).toList();
      orders.add(OrderModel.fromMap(headerMap, items: items));
    }

    return orders;
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      final now = DateTime.now();

      // 1. Fetch Order status
      final orderResults = await txn.query(
        'orders',
        columns: ['order_status', 'order_queue'],
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderResults.isEmpty) {
        throw Exception('Pesanan tidak ditemukan');
      }

      final currentStatus = orderResults.first['order_status'] as String;
      final orderQueue = orderResults.first['order_queue'] as int;

      if (currentStatus == OrderStatus.cancelled.toDbString) {
        throw Exception('Pesanan sudah dibatalkan');
      }

      // 2. Fetch Order Items to restore stock
      final itemResults = await txn.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final items = itemResults.map((map) => OrderItemModel.fromMap(map)).toList();

      // 3. Restore Stock
      for (final item in items) {
        if (item.productId != null) {
          final products = await txn.query(
            'products',
            columns: ['is_track_stock', 'stock_quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
            limit: 1,
          );

          if (products.isNotEmpty) {
            final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
            if (isTrackStock) {
              final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
              final restoredStock = currentStock + item.qty;

              await txn.update(
                'products',
                {'stock_quantity': restoredStock},
                where: 'id = ?',
                whereArgs: [item.productId],
              );

              // Log stock transaction
              await txn.insert('stock_transactions', {
                'product_id': item.productId,
                'quantity': item.qty, // positive for restoration
                'type': 'stock_in',
                'reference': 'ORDER-CANCEL-$orderId',
                'notes': 'Pengembalian stok pesanan #$orderQueue dibatalkan',
                'created_at': now.toIso8601String(),
              });
            }
          }
        }
      }

      // 4. Update Order Status
      await txn.update(
        'orders',
        {
          'order_status': OrderStatus.cancelled.toDbString,
          'payment_status': PaymentStatus.refunded.toDbString,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }
}
