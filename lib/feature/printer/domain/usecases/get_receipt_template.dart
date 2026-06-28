import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_template.dart';
import '../repositories/printer_repository.dart';

class GetReceiptTemplate implements UseCase<ReceiptTemplate, NoParams> {
  final PrinterRepository repository;

  GetReceiptTemplate(this.repository);

  @override
  Future<Either<Failure, ReceiptTemplate>> call(NoParams params) async {
    return await repository.getReceiptTemplate();
  }
}
