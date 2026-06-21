import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, int>> createPendingOrder(Order order) async {
    try {
      final model = OrderModel.fromEntity(order);
      final id = await localDataSource.createPendingOrder(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal membuat pesanan pending: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrder(Order order) async {
    try {
      final model = OrderModel.fromEntity(order);
      await localDataSource.updateOrder(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal memperbarui pesanan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> payOrder({
    required int orderId,
    required int paymentOptionId,
    required double cashReceived,
    required double changeGiven,
  }) async {
    try {
      await localDataSource.payOrder(
        orderId: orderId,
        paymentOptionId: paymentOptionId,
        cashReceived: cashReceived,
        changeGiven: changeGiven,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal memproses pembayaran pesanan: $e'));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(int id) async {
    try {
      final model = await localDataSource.getOrderById(id);
      if (model != null) {
        return Right(model.toEntity());
      } else {
        return Left(CacheFailure('Pesanan dengan ID $id tidak ditemukan'));
      }
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil detail pesanan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
  }) async {
    try {
      final models = await localDataSource.getOrders(
        status: status,
        paymentStatus: paymentStatus,
      );
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil daftar pesanan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(int orderId) async {
    try {
      await localDataSource.cancelOrder(orderId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal membatalkan pesanan: $e'));
    }
  }
}
