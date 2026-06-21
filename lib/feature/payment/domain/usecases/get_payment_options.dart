import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_option.dart';
import '../repositories/payment_option_repository.dart';

class GetPaymentOptions implements UseCase<List<PaymentOption>, GetPaymentOptionsParams> {
  final PaymentOptionRepository repository;

  GetPaymentOptions(this.repository);

  @override
  Future<Either<Failure, List<PaymentOption>>> call(GetPaymentOptionsParams params) async {
    return await repository.getPaymentOptions(onlyActive: params.onlyActive);
  }
}

class GetPaymentOptionsParams {
  final bool? onlyActive;

  const GetPaymentOptionsParams({this.onlyActive});
}
