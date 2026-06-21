import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_batch.dart';
import '../repositories/stock_repository.dart';

class GetStockBatches implements UseCase<List<StockBatch>, NoParams> {
  final StockRepository repository;

  GetStockBatches(this.repository);

  @override
  Future<Either<Failure, List<StockBatch>>> call(NoParams params) async {
    return await repository.getStockBatches();
  }
}
