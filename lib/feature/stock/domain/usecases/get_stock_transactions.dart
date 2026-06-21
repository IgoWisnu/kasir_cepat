import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_transaction.dart';
import '../repositories/stock_repository.dart';

class GetStockTransactions implements UseCase<List<StockTransaction>, int> {
  final StockRepository repository;

  GetStockTransactions(this.repository);

  @override
  Future<Either<Failure, List<StockTransaction>>> call(int productId) async {
    return await repository.getStockTransactions(productId);
  }
}
