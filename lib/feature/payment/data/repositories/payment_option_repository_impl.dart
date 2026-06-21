import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_option.dart';
import '../../domain/repositories/payment_option_repository.dart';
import '../datasources/payment_option_local_datasource.dart';
import '../models/payment_option_model.dart';

class PaymentOptionRepositoryImpl implements PaymentOptionRepository {
  final PaymentOptionLocalDataSource localDataSource;

  PaymentOptionRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<PaymentOption>>> getPaymentOptions({bool? onlyActive}) async {
    try {
      final models = await localDataSource.getPaymentOptions(onlyActive: onlyActive);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil opsi pembayaran: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> savePaymentOption(PaymentOption option) async {
    try {
      final model = PaymentOptionModel.fromEntity(option);
      final id = await localDataSource.savePaymentOption(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan opsi pembayaran: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentOption(int id) async {
    try {
      await localDataSource.deletePaymentOption(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus opsi pembayaran: $e'));
    }
  }
}
