import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  final int? id;
  final String name;
  final String abbreviation;
  final DateTime createdAt;

  const Unit({
    this.id,
    required this.name,
    required this.abbreviation,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, abbreviation, createdAt];
}
