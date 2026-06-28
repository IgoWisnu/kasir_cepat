import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../order/domain/entities/order.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/receipt_template.dart';
import '../../domain/repositories/printer_repository.dart';
import '../datasources/printer_local_datasource.dart';
import '../models/printer_model.dart';
import '../models/receipt_template_model.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterLocalDataSource localDataSource;

  PrinterRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<PrinterDevice>>> getPrinters() async {
    try {
      final models = await localDataSource.getPrinters();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil daftar printer: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> savePrinter(PrinterDevice printer) async {
    try {
      final model = PrinterModel.fromEntity(printer);
      final id = await localDataSource.savePrinter(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan printer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrinter(int id) async {
    try {
      await localDataSource.deletePrinter(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus printer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultPrinter(int id) async {
    try {
      await localDataSource.setDefaultPrinter(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menyetel printer utama: $e'));
    }
  }

  @override
  Future<Either<Failure, PrinterDevice?>> getDefaultPrinter() async {
    try {
      final model = await localDataSource.getDefaultPrinter();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil printer utama: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> printReceipt(Order order, PrinterDevice printer) async {
    try {
      final template = await localDataSource.getReceiptTemplate();
      final business = await localDataSource.getBusinessProfile();

      // Formats the receipt into a text string and prints it to the console log
      final buffer = StringBuffer();
      final width = printer.paperSize == 80 ? 40 : 32;

      buffer.writeln('\n');
      buffer.writeln('=' * width);

      // 1. Business Logo
      if (template.showLogo) {
        final logo = business?['logo'] as String?;
        if (logo != null && logo.isNotEmpty) {
          buffer.writeln(_centerText('[LOGO: $logo]', width));
        } else {
          buffer.writeln(_centerText('[LOGO]', width));
        }
      }

      // 2. Business Name
      if (template.showBusinessName) {
        final name = (template.businessNameOverride != null && template.businessNameOverride!.trim().isNotEmpty)
            ? template.businessNameOverride!.trim()
            : (business?['name'] as String? ?? 'KASIR CEPAT');
        buffer.writeln(_centerText(name, width));
      }

      // 3. Business Address
      if (template.showBusinessAddress) {
        final address = (template.businessAddressOverride != null && template.businessAddressOverride!.trim().isNotEmpty)
            ? template.businessAddressOverride!.trim()
            : (business?['address'] as String?);
        if (address != null && address.trim().isNotEmpty) {
          buffer.writeln(_centerText(address, width));
        }
      }

      buffer.writeln('=' * width);
      
      // 4. Transaction Info
      buffer.writeln('Nomor Antrean : #${order.orderQueue}');
      if (template.showTransactionId) {
        buffer.writeln('No. Invoice   : ${order.invoiceNumber ?? "-"}');
      }
      buffer.writeln('Waktu         : ${order.createdAt}');
      buffer.writeln('Tipe Pesanan  : ${order.orderType.name.toUpperCase()}');
      
      if (template.showCustomerName && order.customerName != null) {
        buffer.writeln('Pelanggan     : ${order.customerName}');
      }

      if (template.showCashierName && order.userId != null) {
        final cashierName = await localDataSource.getCashierName(order.userId!);
        if (cashierName != null) {
          buffer.writeln('Kasir         : $cashierName');
        }
      }

      buffer.writeln('-' * width);

      // 5. Items List
      for (final item in order.items) {
        buffer.writeln(item.productName);

        // Show product SKU if config enabled
        if (template.showProductSku && item.productId != null) {
          final sku = await localDataSource.getProductSku(item.productId!);
          if (sku != null && sku.trim().isNotEmpty) {
            buffer.writeln('  SKU: $sku');
          }
        }

        final qtyPrice = '  ${item.qty.toStringAsFixed(0)} x ${_formatCurrency(item.priceAtPurchase)}';
        final sub = _formatCurrency(item.subtotal);
        buffer.writeln(_rowText(qtyPrice, sub, width));
      }
      buffer.writeln('-' * width);

      // 6. Summary Totals
      buffer.writeln(_rowText('Subtotal', _formatCurrency(order.subtotal), width));
      if (order.discountValue > 0) {
        buffer.writeln(_rowText('Diskon', '-${_formatCurrency(order.discountValue)}', width));
      }
      buffer.writeln(_rowText('Total', _formatCurrency(order.grandTotal), width));
      
      if (order.cashReceived != null) {
        buffer.writeln(_rowText('Tunai', _formatCurrency(order.cashReceived!), width));
        buffer.writeln(_rowText('Kembali', _formatCurrency(order.changeGiven!), width));
      }
      
      buffer.writeln('=' * width);

      // 7. Footer text
      final footer = (template.footerText != null && template.footerText!.trim().isNotEmpty)
          ? template.footerText!.trim()
          : (business?['footer_message'] as String? ?? 'Terima Kasih Atas Kunjungan Anda\nSimpan Bukti Pembayaran Ini');
      
      for (final line in footer.split('\n')) {
        if (line.trim().isNotEmpty) {
          buffer.writeln(_centerText(line.trim(), width));
        }
      }

      buffer.writeln('=' * width);
      buffer.writeln('\n');

      // Prints the receipt directly to developer tools console
      // ignore: avoid_print
      print(buffer.toString());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal melakukan pencetakan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> printTestPage(PrinterDevice printer) async {
    try {
      final buffer = StringBuffer();
      final width = printer.paperSize == 80 ? 40 : 32;

      buffer.writeln('\n');
      buffer.writeln('=' * width);
      buffer.writeln(_centerText('TEST PRINTER KASIR CEPAT', width));
      buffer.writeln('=' * width);
      buffer.writeln('Nama Device : ${printer.name}');
      buffer.writeln('Tipe Koneksi: ${printer.connectionType.name.toUpperCase()}');
      buffer.writeln('Alamat      : ${printer.address}');
      buffer.writeln('Lebar Kertas: ${printer.paperSize} mm ($width kolom)');
      buffer.writeln('Status      : ${printer.status.name.toUpperCase()}');
      buffer.writeln('Kitchen     : ${printer.isKitchenPrinter ? 'YA' : 'TIDAK'}');
      buffer.writeln('Default     : ${printer.isDefault ? 'YA' : 'TIDAK'}');
      buffer.writeln('-' * width);
      
      // Alignment check lines
      buffer.writeln('Tes Alignment:');
      buffer.writeln('${'[Kiri]'.padRight(width - 6)}[Kiri]');
      buffer.writeln(_centerText('[Tengah]', width));
      buffer.writeln('[Kanan]'.padLeft(width));
      buffer.writeln('-' * width);
      
      // Character test
      buffer.writeln('Tes Karakter:');
      buffer.writeln('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      buffer.writeln('abcdefghijklmnopqrstuvwxyz');
      buffer.writeln('0123456789 !@#\$%^&*()_+');
      buffer.writeln('=' * width);
      buffer.writeln(_centerText('TEST PRINT SUCCESS', width));
      buffer.writeln('=' * width);
      buffer.writeln('\n');

      // Prints the test receipt directly to developer tools console
      // ignore: avoid_print
      print(buffer.toString());

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal melakukan cetak uji coba: $e'));
    }
  }

  @override
  Future<Either<Failure, ReceiptTemplate>> getReceiptTemplate() async {
    try {
      final model = await localDataSource.getReceiptTemplate();
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil pengaturan struk: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveReceiptTemplate(ReceiptTemplate template) async {
    try {
      final model = ReceiptTemplateModel.fromEntity(template);
      await localDataSource.saveReceiptTemplate(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan pengaturan struk: $e'));
    }
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final spaces = (width - text.length) ~/ 2;
    return ' ' * spaces + text;
  }

  String _rowText(String left, String right, int width) {
    final availableSpace = width - left.length - right.length;
    if (availableSpace <= 0) return '$left $right';
    return left + ' ' * availableSpace + right;
  }

  String _formatCurrency(double val) {
    return 'Rp ${val.toStringAsFixed(0)}';
  }
}
