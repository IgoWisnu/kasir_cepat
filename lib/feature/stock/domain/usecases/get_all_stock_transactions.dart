import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_transaction.dart';
import '../repositories/stock_repository.dart';

class GetAllStockTransactions implements UseCase<List<StockTransaction>, NoParams> {
  final StockRepository repository;

  GetAllStockTransactions(this.repository);

  @override
  Future<Either<Failure, List<StockTransaction>>> call(NoParams params) async {
    return await repository.getAllStockTransactions();
  }
}
