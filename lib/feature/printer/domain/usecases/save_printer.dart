import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/printer.dart';
import '../repositories/printer_repository.dart';

class SavePrinter implements UseCase<int, PrinterDevice> {
  final PrinterRepository repository;

  SavePrinter(this.repository);

  @override
  Future<Either<Failure, int>> call(PrinterDevice printer) async {
    return await repository.savePrinter(printer);
  }
}
