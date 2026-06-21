import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  /// Inserts a new pending order and its items.
  /// Also adjusts stock levels for all products configured to track stock.
  Future<Either<Failure, int>> createPendingOrder(Order order);

  /// Updates an existing pending order (adds/removes items, recalculates totals).
  /// Re-adjusts stock based on quantity changes.
  Future<Either<Failure, void>> updateOrder(Order order);

  /// Processes the payment of an order, changing status to completed and updating payment details.
  Future<Either<Failure, void>> payOrder({
    required int orderId,
    required int paymentOptionId,
    required double cashReceived,
    required double changeGiven,
  });

  /// Retrieves an order by its ID.
  Future<Either<Failure, Order>> getOrderById(int id);

  /// Retrieves a list of orders, optionally filtered by status.
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
  });

  /// Cancels an order, restoring product stock levels.
  Future<Either<Failure, void>> cancelOrder(int orderId);
}
