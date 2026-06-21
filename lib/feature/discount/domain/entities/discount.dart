import 'package:equatable/equatable.dart';

class Discount extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final String valueType; // 'percentage' or 'fixed'
  final double value;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  const Discount({
    this.id,
    required this.name,
    this.description,
    required this.valueType,
    required this.value,
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        valueType,
        value,
        startDate,
        endDate,
        isActive,
        createdAt,
      ];
}
