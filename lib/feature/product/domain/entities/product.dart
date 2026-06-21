import 'package:equatable/equatable.dart';

enum ProductStatus {
  available,
  unavailable;

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductStatus.available,
    );
  }
}

class Product extends Equatable {
  final int? id;
  final String name;
  final int? categoryId;
  final String? categoryName; // Loaded via SQL LEFT JOIN for UI convenience
  final int? unitId;
  final String? unitAbbreviation; // Loaded via SQL LEFT JOIN for UI convenience
  final double sellingPrice;
  final double? costPrice;
  final String? description;
  final String? imagePath;
  final ProductStatus status;
  final bool isTrackStock;
  final double stockQuantity;
  final String? barcode;
  final String? sku;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.unitAbbreviation,
    required this.sellingPrice,
    this.costPrice,
    this.description,
    this.imagePath,
    this.status = ProductStatus.available,
    this.isTrackStock = false,
    this.stockQuantity = 0.0,
    this.barcode,
    this.sku,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        categoryId,
        categoryName,
        unitId,
        unitAbbreviation,
        sellingPrice,
        costPrice,
        description,
        imagePath,
        status,
        isTrackStock,
        stockQuantity,
        barcode,
        sku,
        isActive,
        createdAt,
      ];

  /// Helper copyWith to make it easier to clone and edit products
  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? categoryName,
    int? unitId,
    String? unitAbbreviation,
    double? sellingPrice,
    double? costPrice,
    String? description,
    String? imagePath,
    ProductStatus? status,
    bool? isTrackStock,
    double? stockQuantity,
    String? barcode,
    String? sku,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unitId: unitId ?? this.unitId,
      unitAbbreviation: unitAbbreviation ?? this.unitAbbreviation,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      isTrackStock: isTrackStock ?? this.isTrackStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
