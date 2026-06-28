import 'package:equatable/equatable.dart';

class ProductSellingReport extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final List<ProductSellingItem> items;

  const ProductSellingReport({
    required this.startDate,
    required this.endDate,
    required this.items,
  });

  @override
  List<Object?> get props => [startDate, endDate, items];
}

class ProductSellingItem extends Equatable {
  final int productId;
  final String productName;
  final String? productSku;
  final double quantitySold;
  final double totalSales;

  const ProductSellingItem({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.quantitySold,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        quantitySold,
        totalSales,
      ];
}
