import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, createdAt];
}
