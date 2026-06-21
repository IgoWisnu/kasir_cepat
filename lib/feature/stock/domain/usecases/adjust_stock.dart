import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/stock_repository.dart';

class AdjustStock implements UseCase<void, AdjustStockParams> {
  final StockRepository repository;

  AdjustStock(this.repository);

  @override
  Future<Either<Failure, void>> call(AdjustStockParams params) async {
    return await repository.adjustStock(
      productId: params.productId,
      newQuantity: params.newQuantity,
      notes: params.notes,
    );
  }
}

class AdjustStockParams {
  final int productId;
  final double newQuantity;
  final String? notes;

  const AdjustStockParams({
    required this.productId,
    required this.newQuantity,
    this.notes,
  });
}
