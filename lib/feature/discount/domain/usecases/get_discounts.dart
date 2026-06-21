import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/discount.dart';
import '../repositories/discount_repository.dart';

class GetDiscounts implements UseCase<List<Discount>, NoParams> {
  final DiscountRepository repository;

  GetDiscounts(this.repository);

  @override
  Future<Either<Failure, List<Discount>>> call(NoParams params) async {
    return await repository.getDiscounts();
  }
}
