import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrderById implements UseCase<Order, int> {
  final OrderRepository repository;

  GetOrderById(this.repository);

  @override
  Future<Either<Failure, Order>> call(int id) async {
    return await repository.getOrderById(id);
  }
}
