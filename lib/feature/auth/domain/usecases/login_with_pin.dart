import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../user/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithPin implements UseCase<User, LoginWithPinParams> {
  final AuthRepository repository;

  LoginWithPin(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginWithPinParams params) async {
    return await repository.loginWithPin(params.user, params.pin);
  }
}

class LoginWithPinParams {
  final User user;
  final String pin;

  const LoginWithPinParams({
    required this.user,
    required this.pin,
  });
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
