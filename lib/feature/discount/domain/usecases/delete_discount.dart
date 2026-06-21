import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/discount_repository.dart';

class DeleteDiscount implements UseCase<void, int> {
  final DiscountRepository repository;

  DeleteDiscount(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteDiscount(id);
  }
}
