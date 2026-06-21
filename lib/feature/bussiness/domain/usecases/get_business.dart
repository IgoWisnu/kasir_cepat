import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

class GetBusiness implements UseCase<Business?, NoParams> {
  final BusinessRepository repository;

  GetBusiness(this.repository);

  @override
  Future<Either<Failure, Business?>> call(NoParams params) async {
    return await repository.getBusiness();
  }
}
