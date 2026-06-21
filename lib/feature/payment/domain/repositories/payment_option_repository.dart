import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_option.dart';

abstract class PaymentOptionRepository {
  /// Fetches all payment options, optionally filtered by active status.
  Future<Either<Failure, List<PaymentOption>>> getPaymentOptions({bool? onlyActive});

  /// Saves (creates or updates) a payment option.
  /// Returns the ID of the saved payment option.
  Future<Either<Failure, int>> savePaymentOption(PaymentOption option);

  /// Deletes a payment option by its ID.
  Future<Either<Failure, void>> deletePaymentOption(int id);
}
