import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/stock_local_datasource.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/usecases/adjust_stock.dart';
import '../../domain/usecases/create_opname_batch.dart';
import '../../domain/usecases/create_restock_batch.dart';
import '../../domain/usecases/get_stock_batches.dart';
import '../../domain/usecases/get_stock_transactions.dart';
import '../../domain/usecases/get_all_stock_transactions.dart';

// 1. Database & Source Providers
final stockDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final stockLocalDataSourceProvider = Provider<StockLocalDataSource>((ref) {
  return StockLocalDataSourceImpl(ref.watch(stockDatabaseHelperProvider));
});

// 2. Repository Provider
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepositoryImpl(ref.watch(stockLocalDataSourceProvider));
});

// 3. Use Case Providers
final adjustStockUseCaseProvider = Provider<AdjustStock>((ref) {
  return AdjustStock(ref.watch(stockRepositoryProvider));
});

final createRestockBatchUseCaseProvider = Provider<CreateRestockBatch>((ref) {
  return CreateRestockBatch(ref.watch(stockRepositoryProvider));
});

final createOpnameBatchUseCaseProvider = Provider<CreateOpnameBatch>((ref) {
  return CreateOpnameBatch(ref.watch(stockRepositoryProvider));
});

final getStockTransactionsUseCaseProvider = Provider<GetStockTransactions>((ref) {
  return GetStockTransactions(ref.watch(stockRepositoryProvider));
});

final getStockBatchesUseCaseProvider = Provider<GetStockBatches>((ref) {
  return GetStockBatches(ref.watch(stockRepositoryProvider));
});

final getAllStockTransactionsUseCaseProvider = Provider<GetAllStockTransactions>((ref) {
  return GetAllStockTransactions(ref.watch(stockRepositoryProvider));
});

// 4. State Notifier for Stock Movements (all transactions)
class StockMovementNotifier extends StateNotifier<AsyncValue<List<StockTransaction>>> {
  final GetAllStockTransactions getAllStockTransactions;

  StockMovementNotifier({required this.getAllStockTransactions}) : super(const AsyncValue.loading()) {
    loadMovements();
  }

  Future<void> loadMovements() async {
    state = const AsyncValue.loading();
    final result = await getAllStockTransactions(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (movements) => state = AsyncValue.data(movements),
    );
  }
}

final stockMovementProvider = StateNotifierProvider<StockMovementNotifier, AsyncValue<List<StockTransaction>>>((ref) {
  return StockMovementNotifier(
    getAllStockTransactions: ref.watch(getAllStockTransactionsUseCaseProvider),
  );
});
