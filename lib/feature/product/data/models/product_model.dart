import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    super.id,
    required super.name,
    super.categoryId,
    super.categoryName,
    super.unitId,
    super.unitAbbreviation,
    required super.sellingPrice,
    super.costPrice,
    super.description,
    super.imagePath,
    super.status,
    super.isTrackStock = false,
    super.stockQuantity = 0.0,
    super.barcode,
    super.sku,
    super.isActive = true,
    required super.createdAt,
  });

  /// Creates a [ProductModel] from a database Map.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?, // Loaded from JOIN
      unitId: map['unit_id'] as int?,
      unitAbbreviation: map['unit_abbreviation'] as String?, // Loaded from JOIN
      sellingPrice: (map['price'] as num).toDouble(),
      costPrice: map['cost_price'] != null ? (map['cost_price'] as num).toDouble() : null,
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      status: ProductStatus.fromString(map['status'] as String? ?? 'available'),
      isTrackStock: (map['is_track_stock'] as int? ?? 0) == 1,
      stockQuantity: (map['stock_quantity'] as num? ?? 0.0).toDouble(),
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category_id': categoryId,
      'unit_id': unitId,
      'price': sellingPrice,
      'cost_price': costPrice,
      'description': description,
      'image_path': imagePath,
      'status': status.name,
      'is_track_stock': isTrackStock ? 1 : 0,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
      'sku': sku,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [Product] entity to a [ProductModel].
  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      unitId: entity.unitId,
      unitAbbreviation: entity.unitAbbreviation,
      sellingPrice: entity.sellingPrice,
      costPrice: entity.costPrice,
      description: entity.description,
      imagePath: entity.imagePath,
      status: entity.status,
      isTrackStock: entity.isTrackStock,
      stockQuantity: entity.stockQuantity,
      barcode: entity.barcode,
      sku: entity.sku,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [Product] entity.
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      unitId: unitId,
      unitAbbreviation: unitAbbreviation,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      description: description,
      imagePath: imagePath,
      status: status,
      isTrackStock: isTrackStock,
      stockQuantity: stockQuantity,
      barcode: barcode,
      sku: sku,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
