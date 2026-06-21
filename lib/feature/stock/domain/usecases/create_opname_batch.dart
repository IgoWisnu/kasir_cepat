import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/stock_repository.dart';

class CreateOpnameBatch implements UseCase<int, CreateOpnameBatchParams> {
  final StockRepository repository;

  CreateOpnameBatch(this.repository);

  @override
  Future<Either<Failure, int>> call(CreateOpnameBatchParams params) async {
    return await repository.createOpnameBatch(
      items: params.items,
      notes: params.notes,
    );
  }
}

class CreateOpnameBatchParams {
  final Map<int, double> items; // maps product ID to physical counted stock quantity
  final String? notes;

  const CreateOpnameBatchParams({
    required this.items,
    this.notes,
  });
}
