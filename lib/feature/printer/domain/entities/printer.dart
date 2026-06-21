import 'package:equatable/equatable.dart';

enum PrinterConnectionType {
  bluetooth,
  wifi,
  usb;

  static PrinterConnectionType fromString(String value) {
    switch (value) {
      case 'bluetooth':
        return PrinterConnectionType.bluetooth;
      case 'wifi':
        return PrinterConnectionType.wifi;
      case 'usb':
        return PrinterConnectionType.usb;
      default:
        return PrinterConnectionType.wifi;
    }
  }

  String get toDbString {
    switch (this) {
      case PrinterConnectionType.bluetooth:
        return 'bluetooth';
      case PrinterConnectionType.wifi:
        return 'wifi';
      case PrinterConnectionType.usb:
        return 'usb';
    }
  }
}

enum PrinterStatus {
  active,
  inactive;

  static PrinterStatus fromString(String value) {
    switch (value) {
      case 'active':
        return PrinterStatus.active;
      case 'inactive':
        return PrinterStatus.inactive;
      default:
        return PrinterStatus.active;
    }
  }

  String get toDbString {
    switch (this) {
      case PrinterStatus.active:
        return 'active';
      case PrinterStatus.inactive:
        return 'inactive';
    }
  }
}

class PrinterDevice extends Equatable {
  final int? id;
  final String name;
  final PrinterConnectionType connectionType;
  final String address;
  final int paperSize;
  final bool isDefault;
  final bool isKitchenPrinter;
  final PrinterStatus status;

  const PrinterDevice({
    this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.paperSize = 58,
    this.isDefault = false,
    this.isKitchenPrinter = false,
    this.status = PrinterStatus.active,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        connectionType,
        address,
        paperSize,
        isDefault,
        isKitchenPrinter,
        status,
      ];

  PrinterDevice copyWith({
    int? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    int? paperSize,
    bool? isDefault,
    bool? isKitchenPrinter,
    PrinterStatus? status,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      paperSize: paperSize ?? this.paperSize,
      isDefault: isDefault ?? this.isDefault,
      isKitchenPrinter: isKitchenPrinter ?? this.isKitchenPrinter,
      status: status ?? this.status,
    );
  }
}
