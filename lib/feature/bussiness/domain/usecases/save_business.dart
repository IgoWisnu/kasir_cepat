import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

class SaveBusiness implements UseCase<int, Business> {
  final BusinessRepository repository;

  SaveBusiness(this.repository);

  @override
  Future<Either<Failure, int>> call(Business business) async {
    return await repository.saveBusiness(business);
  }
}
