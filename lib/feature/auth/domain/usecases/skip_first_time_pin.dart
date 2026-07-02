import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../user/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class SkipFirstTimePin implements UseCase<void, SkipFirstTimePinParams> {
  final AuthRepository repository;

  SkipFirstTimePin(this.repository);

  @override
  Future<Either<Failure, void>> call(SkipFirstTimePinParams params) async {
    return await repository.skipFirstTimePin(params.user);
  }
}

class SkipFirstTimePinParams {
  final User user;

  const SkipFirstTimePinParams({
    required this.user,
  });
}
