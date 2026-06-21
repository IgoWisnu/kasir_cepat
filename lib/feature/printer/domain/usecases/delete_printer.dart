import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/printer_repository.dart';

class DeletePrinter implements UseCase<void, int> {
  final PrinterRepository repository;

  DeletePrinter(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    return await repository.deletePrinter(id);
  }
}
