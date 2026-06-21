import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class CreatePendingOrder implements UseCase<int, Order> {
  final OrderRepository repository;

  CreatePendingOrder(this.repository);

  @override
  Future<Either<Failure, int>> call(Order order) async {
    return await repository.createPendingOrder(order);
  }
}
