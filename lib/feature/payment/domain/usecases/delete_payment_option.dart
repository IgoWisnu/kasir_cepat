import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/payment_option_repository.dart';

class DeletePaymentOption implements UseCase<void, int> {
  final PaymentOptionRepository repository;

  DeletePaymentOption(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deletePaymentOption(id);
  }
}
