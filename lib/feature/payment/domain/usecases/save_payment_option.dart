import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_option.dart';
import '../repositories/payment_option_repository.dart';

class SavePaymentOption implements UseCase<int, PaymentOption> {
  final PaymentOptionRepository repository;

  SavePaymentOption(this.repository);

  @override
  Future<Either<Failure, int>> call(PaymentOption option) async {
    return await repository.savePaymentOption(option);
  }
}
