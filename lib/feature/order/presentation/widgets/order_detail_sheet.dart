import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../payment/presentation/provider/payment_option_provider.dart';
import '../../../product/presentation/provider/product_provider.dart';
import '../../../pos/presentation/provider/cart_provider.dart';
import '../../../printer/presentation/provider/printer_provider.dart';
import '../../../printer/domain/usecases/print_receipt.dart';
import '../../domain/entities/order.dart';
import '../provider/order_provider.dart';

class OrderDetailSheet extends ConsumerWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  String _getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Dine-In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.newOrder:
      case OrderStatus.processing:
      case OrderStatus.preparing:
        return Colors.orange;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Batal';
      case OrderStatus.newOrder:
        return 'Pesanan Baru';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.preparing:
        return 'Disiapkan';
    }
  }

  Future<void> _onCancelOrder(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Transaksi'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan transaksi ${order.invoiceNumber ?? "#${order.orderQueue}"}?\nStok produk yang terpotong akan otomatis dikembalikan ke inventaris.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(orderListProvider.notifier)
          .cancelOrderById(order.id!);
      if (context.mounted) {
        if (success) {
          ToastHelper.showSuccess(
            context,
            'Transaksi berhasil dibatalkan dan stok dikembalikan.',
          );
          context.pop(); // close sheet
        } else {
          ToastHelper.showError(context, 'Gagal membatalkan transaksi.');
        }
      }
    }
  }

  Future<void> _onReprintReceipt(BuildContext context, WidgetRef ref) async {
    final defaultPrinterAsync = ref.read(defaultPrinterProvider);

    defaultPrinterAsync.when(
      data: (printer) async {
        if (printer != null) {
          ToastHelper.showInfo(context, 'Mencetak kuitansi ulang...');
          final printResult = await ref
              .read(printReceiptUseCaseProvider)
              .call(PrintReceiptParams(order: order, printer: printer));

          if (context.mounted) {
            printResult.fold(
              (failure) => ToastHelper.showError(
                context,
                'Gagal mencetak: ${failure.message}',
              ),
              (_) =>
                  ToastHelper.showSuccess(context, 'Kuitansi dicetak ulang!'),
            );
          }
        } else {
          if (context.mounted) {
            ToastHelper.showWarning(
              context,
              'Printer utama belum disetel. Hubungkan printer di menu Printer.',
            );
          }
        }
      },
      error: (err, _) =>
          ToastHelper.showError(context, 'Gagal membaca printer: $err'),
      loading: () =>
          ToastHelper.showInfo(context, 'Sedang memuat printer utama...'),
    );
  }

  void _onPayNow(BuildContext context, WidgetRef ref) {
    final products = ref
        .read(productListProvider)
        .maybeWhen(data: (list) => list, orElse: () => <dynamic>[]);

    // Load into cart notifier
    ref
        .read(cartProvider.notifier)
        .loadPendingOrder(order, List.from(products));

    // Close sheet and navigate back to POS
    context.pop();
    context.go('/pos');

    ToastHelper.showInfo(
      context,
      'Pesanan dimuat kembali ke kasir untuk diselesaikan',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentOptions = ref
        .watch(paymentOptionListProvider)
        .maybeWhen(data: (options) => options, orElse: () => <dynamic>[]);

    // Find payment method name
    String paymentMethodName = 'Belum Dibayar';
    if (order.paymentStatus == PaymentStatus.paid ||
        order.paymentStatus == PaymentStatus.partial) {
      final matches = paymentOptions.where(
        (opt) => opt.id == order.paymentOptionId,
      );
      final matchedOpt = matches.isNotEmpty ? matches.first : null;
      paymentMethodName = matchedOpt?.name ?? 'Non-Tunai';
    }

    final isCancelled = order.orderStatus == OrderStatus.cancelled;
    final isUnpaid = order.paymentStatus == PaymentStatus.pending;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag indicator and Title
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.invoiceNumber ?? 'Antrean #${order.orderQueue}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    order.orderStatus,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(order.orderStatus),
                  style: TextStyle(
                    color: _getStatusColor(order.orderStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          // Transaction metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaItem(
                'Tipe Pesanan',
                _getOrderTypeLabel(order.orderType),
                LucideIcons.shoppingBag,
              ),
              _buildMetaItem(
                'Nama Pelanggan',
                order.customerName ?? '-',
                LucideIcons.user,
              ),
              _buildMetaItem(
                'Metode Bayar',
                paymentMethodName,
                LucideIcons.creditCard,
              ),
            ],
          ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan: "${order.notes}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24, color: AppColors.border),

          // Items List header
          const Text(
            'Rincian Produk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Items list
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.qty.toStringAsFixed(0)} x ${_formatCurrency(item.priceAtPurchase)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(item.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 24, color: AppColors.border),

          // Payment Summaries
          _buildSummaryRow('Subtotal', _formatCurrency(order.subtotal)),
          if (order.discountValue > 0)
            _buildSummaryRow(
              'Diskon',
              '- ${_formatCurrency(order.discountValue)}',
              valueColor: Colors.red,
            ),
          _buildSummaryRow(
            'Total Tagihan',
            _formatCurrency(order.grandTotal),
            isBold: true,
          ),

          if (order.paymentStatus == PaymentStatus.paid &&
              order.cashReceived != null) ...[
            const SizedBox(height: 4),
            _buildSummaryRow('Tunai', _formatCurrency(order.cashReceived!)),
            _buildSummaryRow(
              'Kembalian',
              _formatCurrency(order.changeGiven!),
              valueColor: Colors.green,
            ),
          ],

          const SizedBox(height: 24),

          // Footer action buttons
          Row(
            children: [
              // Cancel Button (for non-cancelled orders)
              if (!isCancelled) ...[
                Expanded(
                  child: ScaleImpactAnimation(
                    onTap: () => _onCancelOrder(context, ref),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Batalkan',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Pay Now (for pending orders)
              if (isUnpaid && !isCancelled)
                Expanded(
                  child: ScaleImpactAnimation(
                    onTap: () => _onPayNow(context, ref),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.creditCard,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Reprint Receipt (for paid orders)
              if (order.paymentStatus == PaymentStatus.paid)
                Expanded(
                  child: ScaleImpactAnimation(
                    onTap: () => _onReprintReceipt(context, ref),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.printer,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cetak Kuitansi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
