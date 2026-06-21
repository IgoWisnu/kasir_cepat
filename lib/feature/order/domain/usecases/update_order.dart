import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class UpdateOrder implements UseCase<void, Order> {
  final OrderRepository repository;

  UpdateOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(Order order) async {
    return await repository.updateOrder(order);
  }
}
