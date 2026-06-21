import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrders implements UseCase<List<Order>, GetOrdersParams> {
  final OrderRepository repository;

  GetOrders(this.repository);

  @override
  Future<Either<Failure, List<Order>>> call(GetOrdersParams params) async {
    return await repository.getOrders(
      status: params.status,
      paymentStatus: params.paymentStatus,
    );
  }
}

class GetOrdersParams {
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;

  const GetOrdersParams({this.status, this.paymentStatus});
}
