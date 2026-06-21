import 'package:equatable/equatable.dart';

class Business extends Equatable {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? logo;
  final double taxRate;
  final String? footerMessage;
  final DateTime createdAt;

  const Business({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.logo,
    this.taxRate = 0.0,
    this.footerMessage,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        address,
        logo,
        taxRate,
        footerMessage,
        createdAt,
      ];
}
