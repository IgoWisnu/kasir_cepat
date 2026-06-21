import '../../domain/entities/printer.dart';

class PrinterModel extends PrinterDevice {
  const PrinterModel({
    super.id,
    required super.name,
    required super.connectionType,
    required super.address,
    super.paperSize,
    super.isDefault,
    super.isKitchenPrinter,
    super.status,
  });

  factory PrinterModel.fromMap(Map<String, dynamic> map) {
    return PrinterModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      connectionType: PrinterConnectionType.fromString(map['connection_type'] as String),
      address: map['address'] as String,
      paperSize: map['paper_size'] as int? ?? 58,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      isKitchenPrinter: (map['is_kitchen_printer'] as int? ?? 0) == 1,
      status: PrinterStatus.fromString(map['status'] as String? ?? 'active'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'connection_type': connectionType.toDbString,
      'address': address,
      'paper_size': paperSize,
      'is_default': isDefault ? 1 : 0,
      'is_kitchen_printer': isKitchenPrinter ? 1 : 0,
      'status': status.toDbString,
    };
  }

  factory PrinterModel.fromEntity(PrinterDevice entity) {
    return PrinterModel(
      id: entity.id,
      name: entity.name,
      connectionType: entity.connectionType,
      address: entity.address,
      paperSize: entity.paperSize,
      isDefault: entity.isDefault,
      isKitchenPrinter: entity.isKitchenPrinter,
      status: entity.status,
    );
  }

  PrinterDevice toEntity() {
    return PrinterDevice(
      id: id,
      name: name,
      connectionType: connectionType,
      address: address,
      paperSize: paperSize,
      isDefault: isDefault,
      isKitchenPrinter: isKitchenPrinter,
      status: status,
    );
  }

  @override
  PrinterModel copyWith({
    int? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    int? paperSize,
    bool? isDefault,
    bool? isKitchenPrinter,
    PrinterStatus? status,
  }) {
    return PrinterModel(
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
