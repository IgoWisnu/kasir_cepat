import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/stock_batch.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_local_datasource.dart';

class StockRepositoryImpl implements StockRepository {
  final StockLocalDataSource localDataSource;

  StockRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, void>> adjustStock({
    required int productId,
    required double newQuantity,
    String? notes,
  }) async {
    try {
      await localDataSource.adjustStock(
        productId: productId,
        newQuantity: newQuantity,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal melakukan penyesuaian stok: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createRestockBatch({
    required Map<int, double> items,
    String? notes,
    String? reference,
  }) async {
    try {
      final id = await localDataSource.createRestockBatch(
        items: items,
        notes: notes,
        reference: reference,
      );
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan batch restok: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> createOpnameBatch({
    required Map<int, double> items,
    String? notes,
  }) async {
    try {
      final id = await localDataSource.createOpnameBatch(
        items: items,
        notes: notes,
      );
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan batch opname: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StockTransaction>>> getStockTransactions(int productId) async {
    try {
      final models = await localDataSource.getStockTransactions(productId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil riwayat transaksi stok: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StockTransaction>>> getAllStockTransactions() async {
    try {
      final models = await localDataSource.getAllStockTransactions();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil semua riwayat transaksi stok: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StockBatch>>> getStockBatches() async {
    try {
      final models = await localDataSource.getStockBatches();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil daftar batch stok: $e'));
    }
  }

  @override
  Future<Either<Failure, StockBatch>> getStockBatchById(int batchId) async {
    try {
      final model = await localDataSource.getStockBatchById(batchId);
      if (model != null) {
        return Right(model.toEntity());
      } else {
        return Left(CacheFailure('Batch stok dengan ID $batchId tidak ditemukan'));
      }
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil data batch stok: $e'));
    }
  }
}
