import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/stock_batch.dart';
import '../entities/stock_transaction.dart';

abstract class StockRepository {
  /// Adjusts the stock of a single product to a new absolute quantity.
  /// Inserts a stock transaction of type 'adjustment' mapping the difference.
  Future<Either<Failure, void>> adjustStock({
    required int productId,
    required double newQuantity,
    String? notes,
  });

  /// Restocks one or multiple products in a batch.
  /// [items] maps product ID to the quantity to add (must be positive).
  /// Returns the ID of the created stock batch.
  Future<Either<Failure, int>> createRestockBatch({
    required Map<int, double> items,
    String? notes,
    String? reference,
  });

  /// Reconciles stock levels via a stock take/opname batch.
  /// [items] maps product ID to the actual physical quantity counted.
  /// Calculates offsets, updates stocks, and logs transactions.
  /// Returns the ID of the created stock batch.
  Future<Either<Failure, int>> createOpnameBatch({
    required Map<int, double> items,
    String? notes,
  });

  /// Fetches stock transactions for a specific product.
  Future<Either<Failure, List<StockTransaction>>> getStockTransactions(int productId);

  /// Fetches all stock transactions (movements) across all products.
  Future<Either<Failure, List<StockTransaction>>> getAllStockTransactions();

  /// Fetches all stock batches.
  Future<Either<Failure, List<StockBatch>>> getStockBatches();

  /// Fetches a specific stock batch by ID, including its nested transaction items.
  Future<Either<Failure, StockBatch>> getStockBatchById(int batchId);
}
