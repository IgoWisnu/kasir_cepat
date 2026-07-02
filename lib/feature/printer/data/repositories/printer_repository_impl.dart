import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../order/domain/entities/order.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/receipt_template.dart';
import '../../domain/repositories/printer_repository.dart';
import '../datasources/printer_local_datasource.dart';
import '../models/printer_model.dart';
import '../models/receipt_template_model.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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

      // Connect to printer
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        final bool connectResult = await PrintBluetoothThermal.connect(macPrinterAddress: printer.address);
        if (!connectResult) {
          return Left(CacheFailure('Gagal terhubung ke printer ${printer.name} (${printer.address})'));
        }
      }

      // Initialize generator
      final profile = await CapabilityProfile.load();
      final paperSize = printer.paperSize == 80 ? PaperSize.mm80 : PaperSize.mm58;
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      bytes += generator.reset();

      // 1. Business Logo / Name
      if (template.showBusinessName) {
        final name = (template.businessNameOverride != null && template.businessNameOverride!.trim().isNotEmpty)
            ? template.businessNameOverride!.trim()
            : (business?['name'] as String? ?? 'KASIR CEPAT');
        bytes += generator.text(
          name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
      }

      // 2. Business Address
      if (template.showBusinessAddress) {
        final address = (template.businessAddressOverride != null && template.businessAddressOverride!.trim().isNotEmpty)
            ? template.businessAddressOverride!.trim()
            : (business?['address'] as String?);
        if (address != null && address.trim().isNotEmpty) {
          bytes += generator.text(
            address,
            styles: const PosStyles(align: PosAlign.center),
          );
        }
      }

      bytes += generator.hr();

      // 3. Transaction Info
      bytes += generator.text('No. Antrean: #${order.orderQueue}', styles: const PosStyles(bold: true));
      if (template.showTransactionId && order.invoiceNumber != null) {
        bytes += generator.text('Invoice    : ${order.invoiceNumber}');
      }
      bytes += generator.text('Waktu      : ${order.createdAt.toString().split('.')[0]}');
      bytes += generator.text('Tipe       : ${order.orderType.name.toUpperCase()}');

      if (template.showCustomerName && order.customerName != null) {
        bytes += generator.text('Pelanggan  : ${order.customerName}');
      }

      if (template.showCashierName && order.userId != null) {
        final cashierName = await localDataSource.getCashierName(order.userId!);
        if (cashierName != null) {
          bytes += generator.text('Kasir      : $cashierName');
        }
      }

      bytes += generator.hr();

      // 4. Items List
      for (final item in order.items) {
        bytes += generator.text(item.productName, styles: const PosStyles(bold: true));
        
        if (template.showProductSku && item.productId != null) {
          final sku = await localDataSource.getProductSku(item.productId!);
          if (sku != null && sku.trim().isNotEmpty) {
            bytes += generator.text('  SKU: $sku');
          }
        }

        final qtyPrice = '${item.qty.toStringAsFixed(0)} x ${_formatCurrency(item.priceAtPurchase)}';
        final sub = _formatCurrency(item.subtotal);
        bytes += generator.row([
          PosColumn(text: qtyPrice, width: 8, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: sub, width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();

      // 5. Totals
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: _formatCurrency(order.subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (order.discountValue > 0) {
        bytes += generator.row([
          PosColumn(text: 'Diskon', width: 6, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: '-${_formatCurrency(order.discountValue)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'Total', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: _formatCurrency(order.grandTotal), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      if (order.cashReceived != null) {
        bytes += generator.row([
          PosColumn(text: 'Bayar Tunai', width: 6, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: _formatCurrency(order.cashReceived!), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Kembali', width: 6, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: _formatCurrency(order.changeGiven!), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();

      // 6. Footer
      final footer = (template.footerText != null && template.footerText!.trim().isNotEmpty)
          ? template.footerText!.trim()
          : (business?['footer_message'] as String? ?? 'Terima Kasih\nSimpan Bukti Pembayaran Ini');

      for (final line in footer.split('\n')) {
        if (line.trim().isNotEmpty) {
          bytes += generator.text(line.trim(), styles: const PosStyles(align: PosAlign.center));
        }
      }

      bytes += generator.feed(3);
      bytes += generator.cut();

      // Send bytes to printer
      final bool printResult = await PrintBluetoothThermal.writeBytes(bytes);
      if (!printResult) {
        return Left(CacheFailure('Gagal mengirim data cetak ke printer Bluetooth.'));
      }

      // Brief delay to allow buffer to print before disconnect
      await Future.delayed(const Duration(seconds: 1));
      await PrintBluetoothThermal.disconnect;

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal melakukan pencetakan: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> printTestPage(PrinterDevice printer) async {
    try {
      // Connect to printer
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        final bool connectResult = await PrintBluetoothThermal.connect(macPrinterAddress: printer.address);
        if (!connectResult) {
          return Left(CacheFailure('Gagal terhubung ke printer ${printer.name} (${printer.address})'));
        }
      }

      final profile = await CapabilityProfile.load();
      final paperSize = printer.paperSize == 80 ? PaperSize.mm80 : PaperSize.mm58;
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += generator.text(
        'TEST PRINTER KASIR CEPAT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.hr();
      bytes += generator.text('Nama Device  : ${printer.name}');
      bytes += generator.text('Alamat MAC   : ${printer.address}');
      bytes += generator.text('Lebar Kertas : ${printer.paperSize}mm');
      bytes += generator.text('Status       : KONEKSI BERHASIL');
      bytes += generator.hr();
      bytes += generator.text(
        'Printer Berfungsi Normal',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      final bool printResult = await PrintBluetoothThermal.writeBytes(bytes);
      if (!printResult) {
        return Left(CacheFailure('Gagal mengirim data halaman uji ke printer Bluetooth.'));
      }

      await Future.delayed(const Duration(seconds: 1));
      await PrintBluetoothThermal.disconnect;

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal mencetak halaman uji: $e'));
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



  String _formatCurrency(double val) {
    return 'Rp ${val.toStringAsFixed(0)}';
  }
}
