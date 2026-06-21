import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../models/stock_batch_model.dart';
import '../models/stock_transaction_model.dart';
import '../../domain/entities/stock_batch.dart';
import '../../domain/entities/stock_transaction.dart';

abstract class StockLocalDataSource {
  /// Adjusts product stock to a new absolute value.
  Future<void> adjustStock({
    required int productId,
    required double newQuantity,
    String? notes,
  });

  /// Restocks multiple products in a database transaction block.
  Future<int> createRestockBatch({
    required Map<int, double> items,
    String? notes,
    String? reference,
  });

  /// Performs stock take / opname for multiple products in a database transaction block.
  Future<int> createOpnameBatch({
    required Map<int, double> items,
    String? notes,
  });

  /// Fetches stock transactions for a specific product.
  Future<List<StockTransactionModel>> getStockTransactions(int productId);

  /// Fetches all stock transactions (movements) across all products.
  Future<List<StockTransactionModel>> getAllStockTransactions();

  /// Fetches all stock batches.
  Future<List<StockBatchModel>> getStockBatches();

  /// Fetches a specific batch with its child transactions.
  Future<StockBatchModel?> getStockBatchById(int batchId);
}

class StockLocalDataSourceImpl implements StockLocalDataSource {
  final DatabaseHelper databaseHelper;

  StockLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<void> adjustStock({
    required int productId,
    required double newQuantity,
    String? notes,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      // 1. Verify product tracks stock
      final products = await txn.query(
        'products',
        columns: ['is_track_stock', 'stock_quantity'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (products.isEmpty) {
        throw Exception('Produk tidak ditemukan');
      }

      final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
      if (!isTrackStock) {
        throw Exception('Produk tidak dikonfigurasi untuk melacak stok');
      }

      final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
      final difference = newQuantity - currentStock;

      if (difference == 0) return; // No change needed


      // 2. Insert Stock Transaction Log
      final txnModel = StockTransactionModel(
        productId: productId,
        quantity: difference,
        type: StockTransactionType.adjustment,
        notes: notes ?? 'Penyesuaian stok manual',
        createdAt: DateTime.now(),
      );
      await txn.insert('stock_transactions', txnModel.toMap());

      // 3. Update Product Stock Quantity
      await txn.update(
        'products',
        {'stock_quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );
    });
  }

  @override
  Future<int> createRestockBatch({
    required Map<int, double> items,
    String? notes,
    String? reference,
  }) async {
    if (items.isEmpty) {
      throw Exception('Daftar barang restok kosong');
    }

    final db = await databaseHelper.database;
    int batchId = 0;

    await db.transaction((txn) async {
      final now = DateTime.now();
      final dateFormatted = DateFormat('yyyyMMdd-HHmmss').format(now);
      final batchNo = 'RST-$dateFormatted';

      // 1. Insert Batch Header
      final batchModel = StockBatchModel(
        batchNo: batchNo,
        type: StockBatchType.restock,
        notes: notes ?? 'Restok Batch',
        createdAt: now,
      );
      batchId = await txn.insert('stock_batches', batchModel.toMap());

      // 2. Process each item
      for (final entry in items.entries) {
        final productId = entry.key;
        final restockQty = entry.value;

        if (restockQty <= 0) continue; // Only accept positive quantities for restocking

        // Check stock tracking status
        final products = await txn.query(
          'products',
          columns: ['is_track_stock', 'stock_quantity'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (products.isEmpty) {
          throw Exception('Produk dengan ID $productId tidak ditemukan');
        }

        final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
        if (!isTrackStock) {
          throw Exception('Produk ID $productId tidak dikonfigurasi untuk melacak stok');
        }

        final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
        final newStock = currentStock + restockQty;

        // Insert Transaction log
        final txLog = StockTransactionModel(
          productId: productId,
          batchId: batchId,
          quantity: restockQty,
          type: StockTransactionType.restock,
          reference: reference,
          notes: 'Restok barang',
          createdAt: now,
        );
        await txn.insert('stock_transactions', txLog.toMap());

        // Update Product Stock
        await txn.update(
          'products',
          {'stock_quantity': newStock},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    });

    return batchId;
  }

  @override
  Future<int> createOpnameBatch({
    required Map<int, double> items,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw Exception('Daftar barang opname kosong');
    }

    final db = await databaseHelper.database;
    int batchId = 0;

    await db.transaction((txn) async {
      final now = DateTime.now();
      final dateFormatted = DateFormat('yyyyMMdd-HHmmss').format(now);
      final batchNo = 'OPN-$dateFormatted';

      // 1. Insert Batch Header
      final batchModel = StockBatchModel(
        batchNo: batchNo,
        type: StockBatchType.opname,
        notes: notes ?? 'Stock Opname Batch',
        createdAt: now,
      );
      batchId = await txn.insert('stock_batches', batchModel.toMap());

      // 2. Process each item
      for (final entry in items.entries) {
        final productId = entry.key;
        final physicalQty = entry.value;

        // Check stock tracking status
        final products = await txn.query(
          'products',
          columns: ['is_track_stock', 'stock_quantity'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (products.isEmpty) {
          throw Exception('Produk dengan ID $productId tidak ditemukan');
        }

        final isTrackStock = (products.first['is_track_stock'] as int? ?? 0) == 1;
        if (!isTrackStock) {
          throw Exception('Produk ID $productId tidak dikonfigurasi untuk melacak stok');
        }

        final currentStock = (products.first['stock_quantity'] as num? ?? 0.0).toDouble();
        final difference = physicalQty - currentStock;

        if (difference == 0) continue; // No offset transaction needed, stock matches

        // Insert Transaction offset log
        final txLog = StockTransactionModel(
          productId: productId,
          batchId: batchId,
          quantity: difference,
          type: StockTransactionType.opname,
          notes: 'Opname: System $currentStock, Fisik $physicalQty',
          createdAt: now,
        );
        await txn.insert('stock_transactions', txLog.toMap());

        // Update Product Stock to physical quantity
        await txn.update(
          'products',
          {'stock_quantity': physicalQty},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    });

    return batchId;
  }

  @override
  Future<List<StockTransactionModel>> getStockTransactions(int productId) async {
    final db = await databaseHelper.database;
    
    final query = '''
      SELECT t.*, p.name AS product_name
      FROM stock_transactions t
      INNER JOIN products p ON t.product_id = p.id
      WHERE t.product_id = ?
      ORDER BY t.created_at DESC
    ''';
    
    final results = await db.rawQuery(query, [productId]);
    return results.map((map) => StockTransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<StockTransactionModel>> getAllStockTransactions() async {
    final db = await databaseHelper.database;
    
    final query = '''
      SELECT t.*, p.name AS product_name
      FROM stock_transactions t
      INNER JOIN products p ON t.product_id = p.id
      ORDER BY t.created_at DESC
    ''';
    
    final results = await db.rawQuery(query);
    return results.map((map) => StockTransactionModel.fromMap(map)).toList();
  }

  @override
  Future<List<StockBatchModel>> getStockBatches() async {
    final db = await databaseHelper.database;
    
    final results = await db.query('stock_batches', orderBy: 'created_at DESC');
    return results.map((map) => StockBatchModel.fromMap(map)).toList();
  }

  @override
  Future<StockBatchModel?> getStockBatchById(int batchId) async {
    final db = await databaseHelper.database;

    // 1. Fetch Batch Header
    final batchResults = await db.query(
      'stock_batches',
      where: 'id = ?',
      whereArgs: [batchId],
      limit: 1,
    );

    if (batchResults.isEmpty) return null;

    // 2. Fetch Batch child items
    final queryItems = '''
      SELECT t.*, p.name AS product_name
      FROM stock_transactions t
      INNER JOIN products p ON t.product_id = p.id
      WHERE t.batch_id = ?
      ORDER BY t.created_at ASC
    ''';
    
    final itemResults = await db.rawQuery(queryItems, [batchId]);
    final models = itemResults.map((map) => StockTransactionModel.fromMap(map)).toList();

    return StockBatchModel.fromMap(batchResults.first, items: models);
  }
}
