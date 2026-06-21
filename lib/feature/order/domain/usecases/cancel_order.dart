import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/order_repository.dart';

class CancelOrder implements UseCase<void, int> {
  final OrderRepository repository;

  CancelOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(int orderId) async {
    return await repository.cancelOrder(orderId);
  }
}
