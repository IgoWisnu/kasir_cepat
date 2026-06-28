import '../../domain/entities/receipt_template.dart';

class ReceiptTemplateModel extends ReceiptTemplate {
  const ReceiptTemplateModel({
    super.id,
    required super.showLogo,
    required super.showBusinessName,
    super.businessNameOverride,
    required super.showBusinessAddress,
    super.businessAddressOverride,
    required super.showTransactionId,
    required super.showCustomerName,
    required super.showCashierName,
    required super.showProductSku,
    super.footerText,
  });

  factory ReceiptTemplateModel.fromMap(Map<String, dynamic> map) {
    return ReceiptTemplateModel(
      id: map['id'] as int?,
      showLogo: (map['show_logo'] as int? ?? 1) == 1,
      showBusinessName: (map['show_business_name'] as int? ?? 1) == 1,
      businessNameOverride: map['business_name_override'] as String?,
      showBusinessAddress: (map['show_business_address'] as int? ?? 1) == 1,
      businessAddressOverride: map['business_address_override'] as String?,
      showTransactionId: (map['show_transaction_id'] as int? ?? 1) == 1,
      showCustomerName: (map['show_customer_name'] as int? ?? 1) == 1,
      showCashierName: (map['show_cashier_name'] as int? ?? 1) == 1,
      showProductSku: (map['show_product_sku'] as int? ?? 0) == 1,
      footerText: map['footer_text'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'show_logo': showLogo ? 1 : 0,
      'show_business_name': showBusinessName ? 1 : 0,
      'business_name_override': businessNameOverride,
      'show_business_address': showBusinessAddress ? 1 : 0,
      'business_address_override': businessAddressOverride,
      'show_transaction_id': showTransactionId ? 1 : 0,
      'show_customer_name': showCustomerName ? 1 : 0,
      'show_cashier_name': showCashierName ? 1 : 0,
      'show_product_sku': showProductSku ? 1 : 0,
      'footer_text': footerText,
    };
  }

  factory ReceiptTemplateModel.fromEntity(ReceiptTemplate entity) {
    return ReceiptTemplateModel(
      id: entity.id,
      showLogo: entity.showLogo,
      showBusinessName: entity.showBusinessName,
      businessNameOverride: entity.businessNameOverride,
      showBusinessAddress: entity.showBusinessAddress,
      businessAddressOverride: entity.businessAddressOverride,
      showTransactionId: entity.showTransactionId,
      showCustomerName: entity.showCustomerName,
      showCashierName: entity.showCashierName,
      showProductSku: entity.showProductSku,
      footerText: entity.footerText,
    );
  }

  ReceiptTemplate toEntity() {
    return ReceiptTemplate(
      id: id,
      showLogo: showLogo,
      showBusinessName: showBusinessName,
      businessNameOverride: businessNameOverride,
      showBusinessAddress: showBusinessAddress,
      businessAddressOverride: businessAddressOverride,
      showTransactionId: showTransactionId,
      showCustomerName: showCustomerName,
      showCashierName: showCashierName,
      showProductSku: showProductSku,
      footerText: footerText,
    );
  }

  @override
  ReceiptTemplateModel copyWith({
    int? id,
    bool? showLogo,
    bool? showBusinessName,
    String? businessNameOverride,
    bool? showBusinessAddress,
    String? businessAddressOverride,
    bool? showTransactionId,
    bool? showCustomerName,
    bool? showCashierName,
    bool? showProductSku,
    String? footerText,
  }) {
    return ReceiptTemplateModel(
      id: id ?? this.id,
      showLogo: showLogo ?? this.showLogo,
      showBusinessName: showBusinessName ?? this.showBusinessName,
      businessNameOverride: businessNameOverride ?? this.businessNameOverride,
      showBusinessAddress: showBusinessAddress ?? this.showBusinessAddress,
      businessAddressOverride: businessAddressOverride ?? this.businessAddressOverride,
      showTransactionId: showTransactionId ?? this.showTransactionId,
      showCustomerName: showCustomerName ?? this.showCustomerName,
      showCashierName: showCashierName ?? this.showCashierName,
      showProductSku: showProductSku ?? this.showProductSku,
      footerText: footerText ?? this.footerText,
    );
  }
}
