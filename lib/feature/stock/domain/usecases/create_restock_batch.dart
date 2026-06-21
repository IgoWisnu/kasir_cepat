import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/stock_repository.dart';

class CreateRestockBatch implements UseCase<int, CreateRestockBatchParams> {
  final StockRepository repository;

  CreateRestockBatch(this.repository);

  @override
  Future<Either<Failure, int>> call(CreateRestockBatchParams params) async {
    return await repository.createRestockBatch(
      items: params.items,
      notes: params.notes,
      reference: params.reference,
    );
  }
}

class CreateRestockBatchParams {
  final Map<int, double> items; // maps product ID to restock quantity
  final String? notes;
  final String? reference;

  const CreateRestockBatchParams({
    required this.items,
    this.notes,
    this.reference,
  });
}
