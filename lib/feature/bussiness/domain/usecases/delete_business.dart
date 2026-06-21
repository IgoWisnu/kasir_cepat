import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/business_repository.dart';

class DeleteBusiness implements UseCase<void, int> {
  final BusinessRepository repository;

  DeleteBusiness(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteBusiness(id);
  }
}
