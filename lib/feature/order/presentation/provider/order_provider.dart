import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/cancel_order.dart';
import '../../domain/usecases/create_pending_order.dart';
import '../../domain/usecases/get_order_by_id.dart';
import '../../domain/usecases/get_orders.dart';
import '../../domain/usecases/pay_order.dart';
import '../../domain/usecases/update_order.dart';

// 1. Database & Source Providers
final orderDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final orderLocalDataSourceProvider = Provider<OrderLocalDataSource>((ref) {
  return OrderLocalDataSourceImpl(ref.watch(orderDatabaseHelperProvider));
});

// 2. Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderLocalDataSourceProvider));
});

// 3. Use Case Providers
final createPendingOrderUseCaseProvider = Provider<CreatePendingOrder>((ref) {
  return CreatePendingOrder(ref.watch(orderRepositoryProvider));
});

final updateOrderUseCaseProvider = Provider<UpdateOrder>((ref) {
  return UpdateOrder(ref.watch(orderRepositoryProvider));
});

final payOrderUseCaseProvider = Provider<PayOrder>((ref) {
  return PayOrder(ref.watch(orderRepositoryProvider));
});

final getOrderByIdUseCaseProvider = Provider<GetOrderById>((ref) {
  return GetOrderById(ref.watch(orderRepositoryProvider));
});

final getOrdersUseCaseProvider = Provider<GetOrders>((ref) {
  return GetOrders(ref.watch(orderRepositoryProvider));
});

final cancelOrderUseCaseProvider = Provider<CancelOrder>((ref) {
  return CancelOrder(ref.watch(orderRepositoryProvider));
});

// 4. State Notifier managing the List of Orders
class OrderListNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final CreatePendingOrder createPendingOrder;
  final UpdateOrder updateOrder;
  final PayOrder payOrder;
  final GetOrders getOrders;
  final CancelOrder cancelOrder;

  OrderStatus? _currentStatusFilter;
  PaymentStatus? _currentPaymentFilter;

  OrderListNotifier({
    required this.createPendingOrder,
    required this.updateOrder,
    required this.payOrder,
    required this.getOrders,
    required this.cancelOrder,
  }) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  /// Reloads all orders from database.
  Future<void> loadOrders({OrderStatus? status, PaymentStatus? paymentStatus}) async {
    _currentStatusFilter = status;
    _currentPaymentFilter = paymentStatus;
    
    state = const AsyncValue.loading();
    final result = await getOrders(GetOrdersParams(status: status, paymentStatus: paymentStatus));
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (orders) => state = AsyncValue.data(orders),
    );
  }

  /// Creates a new pending order. Returns the new order ID on success, or null.
  Future<int?> createOrder(Order order) async {
    final result = await createPendingOrder(order);
    return result.fold(
      (failure) => null,
      (orderId) {
        loadOrders(status: _currentStatusFilter, paymentStatus: _currentPaymentFilter);
        return orderId;
      },
    );
  }

  /// Updates an existing pending order. Returns true on success.
  Future<bool> updateOrderDetails(Order order) async {
    final result = await updateOrder(order);
    return result.fold(
      (failure) => false,
      (_) {
        loadOrders(status: _currentStatusFilter, paymentStatus: _currentPaymentFilter);
        return true;
      },
    );
  }

  /// Processes the payment of an order. Returns true on success.
  Future<bool> processPayment({
    required int orderId,
    required int paymentOptionId,
    required double cashReceived,
    required double changeGiven,
  }) async {
    final result = await payOrder(PayOrderParams(
      orderId: orderId,
      paymentOptionId: paymentOptionId,
      cashReceived: cashReceived,
      changeGiven: changeGiven,
    ));
    
    return result.fold(
      (failure) => false,
      (_) {
        loadOrders(status: _currentStatusFilter, paymentStatus: _currentPaymentFilter);
        return true;
      },
    );
  }

  /// Cancels an order. Returns true on success.
  Future<bool> cancelOrderById(int orderId) async {
    final result = await cancelOrder(orderId);
    return result.fold(
      (failure) => false,
      (_) {
        loadOrders(status: _currentStatusFilter, paymentStatus: _currentPaymentFilter);
        return true;
      },
    );
  }
}

// 5. Global Order List Provider
final orderListProvider = StateNotifierProvider<OrderListNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderListNotifier(
    createPendingOrder: ref.watch(createPendingOrderUseCaseProvider),
    updateOrder: ref.watch(updateOrderUseCaseProvider),
    payOrder: ref.watch(payOrderUseCaseProvider),
    getOrders: ref.watch(getOrdersUseCaseProvider),
    cancelOrder: ref.watch(cancelOrderUseCaseProvider),
  );
});
