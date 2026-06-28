import 'package:equatable/equatable.dart';

class ReceiptTemplate extends Equatable {
  final int? id;
  final bool showLogo;
  final bool showBusinessName;
  final String? businessNameOverride;
  final bool showBusinessAddress;
  final String? businessAddressOverride;
  final bool showTransactionId;
  final bool showCustomerName;
  final bool showCashierName;
  final bool showProductSku;
  final String? footerText;

  const ReceiptTemplate({
    this.id,
    this.showLogo = true,
    this.showBusinessName = true,
    this.businessNameOverride,
    this.showBusinessAddress = true,
    this.businessAddressOverride,
    this.showTransactionId = true,
    this.showCustomerName = true,
    this.showCashierName = true,
    this.showProductSku = false,
    this.footerText,
  });

  @override
  List<Object?> get props => [
        id,
        showLogo,
        showBusinessName,
        businessNameOverride,
        showBusinessAddress,
        businessAddressOverride,
        showTransactionId,
        showCustomerName,
        showCashierName,
        showProductSku,
        footerText,
      ];

  ReceiptTemplate copyWith({
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
    return ReceiptTemplate(
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
