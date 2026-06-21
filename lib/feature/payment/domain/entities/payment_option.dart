import 'package:equatable/equatable.dart';

enum PaymentOptionType {
  cash,
  nonCash;

  static PaymentOptionType fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentOptionType.cash;
      case 'non-cash':
        return PaymentOptionType.nonCash;
      default:
        return PaymentOptionType.nonCash;
    }
  }

  String get toDbString {
    switch (this) {
      case PaymentOptionType.cash:
        return 'cash';
      case PaymentOptionType.nonCash:
        return 'non-cash';
    }
  }
}

enum PaymentOptionStatus {
  active,
  inactive;

  static PaymentOptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return PaymentOptionStatus.active;
      case 'inactive':
        return PaymentOptionStatus.inactive;
      default:
        return PaymentOptionStatus.active;
    }
  }

  String get toDbString {
    switch (this) {
      case PaymentOptionStatus.active:
        return 'active';
      case PaymentOptionStatus.inactive:
        return 'inactive';
    }
  }
}

class PaymentOption extends Equatable {
  final int? id;
  final String name;
  final PaymentOptionType type;
  final String? icon; // 'banknote', 'qr_code', 'credit_card', etc.
  final String? description;
  final PaymentOptionStatus status;
  final DateTime createdAt;

  const PaymentOption({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.description,
    this.status = PaymentOptionStatus.active,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        icon,
        description,
        status,
        createdAt,
      ];

  PaymentOption copyWith({
    int? id,
    String? name,
    PaymentOptionType? type,
    String? icon,
    String? description,
    PaymentOptionStatus? status,
    DateTime? createdAt,
  }) {
    return PaymentOption(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
