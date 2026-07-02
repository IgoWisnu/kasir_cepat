import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../user/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class GetActiveCashiers implements UseCase<List<User>, NoParams> {
  final AuthRepository repository;

  GetActiveCashiers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(NoParams params) async {
    return await repository.getActiveCashiers();
  }
}
