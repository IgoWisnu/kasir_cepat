import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/printer.dart';
import '../repositories/printer_repository.dart';

class GetPrinters implements UseCase<List<PrinterDevice>, NoParams> {
  final PrinterRepository repository;

  GetPrinters(this.repository);

  @override
  Future<Either<Failure, List<PrinterDevice>>> call(NoParams params) async {
    return await repository.getPrinters();
  }
}
