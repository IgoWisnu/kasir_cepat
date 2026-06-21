import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/discount.dart';
import '../repositories/discount_repository.dart';

class SaveDiscount implements UseCase<int, Discount> {
  final DiscountRepository repository;

  SaveDiscount(this.repository);

  @override
  Future<Either<Failure, int>> call(Discount discount) async {
    return await repository.saveDiscount(discount);
  }
}
