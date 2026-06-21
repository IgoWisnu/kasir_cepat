import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/order_repository.dart';

class PayOrder implements UseCase<void, PayOrderParams> {
  final OrderRepository repository;

  PayOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(PayOrderParams params) async {
    return await repository.payOrder(
      orderId: params.orderId,
      paymentOptionId: params.paymentOptionId,
      cashReceived: params.cashReceived,
      changeGiven: params.changeGiven,
    );
  }
}

class PayOrderParams {
  final int orderId;
  final int paymentOptionId;
  final double cashReceived;
  final double changeGiven;

  const PayOrderParams({
    required this.orderId,
    required this.paymentOptionId,
    required this.cashReceived,
    required this.changeGiven,
  });
}
