import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../user/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateFirstTimePin implements UseCase<void, UpdateFirstTimePinParams> {
  final AuthRepository repository;

  UpdateFirstTimePin(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateFirstTimePinParams params) async {
    return await repository.updateFirstTimePin(params.user, params.newPin);
  }
}

class UpdateFirstTimePinParams {
  final User user;
  final String newPin;

  const UpdateFirstTimePinParams({
    required this.user,
    required this.newPin,
  });
}
