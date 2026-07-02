import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../payment/domain/entities/payment_option.dart';
import '../../payment/presentation/provider/payment_option_provider.dart';
import '../../order/domain/entities/order.dart';
import '../../order/domain/entities/order_item.dart';
import '../../order/presentation/provider/order_provider.dart';
import '../../printer/presentation/provider/printer_provider.dart';
import '../../printer/domain/usecases/print_receipt.dart';
import 'provider/cart_provider.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../../shift/presentation/provider/shift_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _cashController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  PaymentOption? _selectedOption;
  double _cashReceived = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      final text = _cashController.text.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(text) ?? 0.0;
      setState(() {
        _cashReceived = val;
      });
    });

    // Default select first payment option when options load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentOptionListProvider.notifier).loadPaymentOptions(onlyActive: true);
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  List<double> _getQuickCashSuggestions(double total) {
    final List<double> suggestions = [total];
    final bases = [5000.0, 10000.0, 20000.0, 50000.0, 100000.0];
    
    for (final base in bases) {
      if (base > total) {
        final val = (total / base).ceil() * base;
        if (!suggestions.contains(val)) {
          suggestions.add(val);
        }
      }
    }
    return suggestions.take(5).toList();
  }

  IconData _getIconData(String? iconKey) {
    switch (iconKey) {
      case 'banknote':
        return LucideIcons.banknote;
      case 'qr_code':
        return LucideIcons.qrCode;
      case 'credit_card':
        return LucideIcons.creditCard;
      default:
        return LucideIcons.wallet;
    }
  }

  Future<void> _onConfirmPayment(CartState cart) async {
    if (_selectedOption == null) {
      ToastHelper.showError(context, 'Silakan pilih metode pembayaran');
      return;
    }

    final isCash = _selectedOption!.type == PaymentOptionType.cash;
    final double cashReceivedVal = isCash ? _cashReceived : cart.grandTotal;
    
    if (isCash && cashReceivedVal < cart.grandTotal) {
      ToastHelper.showError(context, 'Uang tunai yang diterima kurang');
      return;
    }

    final double changeGivenVal = isCash ? (cashReceivedVal - cart.grandTotal) : 0.0;

    setState(() {
      _isProcessing = true;
    });

    // 1. Prepare Order and Order Items
    final orderItems = cart.items.map((item) {
      return OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        priceAtPurchase: item.product.sellingPrice,
        costPrice: item.product.costPrice ?? 0.0,
        qty: item.quantity,
        discountValue: item.discountValue,
        subtotal: item.subtotal,
        createdAt: DateTime.now(),
      );
    }).toList();

    final activeUser = ref.read(activeUserProvider);
    final activeShift = ref.read(shiftProvider).value;

    final order = Order(
      id: cart.editingOrderId,
      orderQueue: cart.orderQueue ?? 0,
      invoiceNumber: cart.invoiceNumber,
      customerName: cart.customerName.isEmpty ? null : cart.customerName,
      orderType: cart.orderType,
      orderStatus: OrderStatus.newOrder,
      paymentStatus: PaymentStatus.pending,
      subtotal: cart.subtotal,
      grandTotal: cart.grandTotal,
      notes: cart.notes.isEmpty ? null : cart.notes,
      userId: activeUser?.id,
      shiftId: activeShift?.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: orderItems,
    );

    // 2. Insert or update the order
    int? orderId = cart.editingOrderId;
    bool success = false;

    if (orderId != null) {
      final successUpdate = await ref.read(orderListProvider.notifier).updateOrderDetails(order);
      if (!successUpdate && mounted) {
        setState(() => _isProcessing = false);
        ToastHelper.showError(context, 'Gagal memperbarui pesanan');
        return;
      }
    } else {
      orderId = await ref.read(orderListProvider.notifier).createOrder(order);
      if (orderId == null && mounted) {
        setState(() => _isProcessing = false);
        ToastHelper.showError(context, 'Gagal membuat pesanan');
        return;
      }
    }

    // 3. Process payment of the order
    success = await ref.read(orderListProvider.notifier).processPayment(
      orderId: orderId!,
      paymentOptionId: _selectedOption!.id!,
      cashReceived: cashReceivedVal,
      changeGiven: changeGivenVal,
    );

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      if (success) {
        // Fetch completed order details to show receipt details
        final completedOrderResult = await ref.read(getOrderByIdUseCaseProvider).call(orderId);
        completedOrderResult.fold(
          (failure) {
            ToastHelper.showSuccess(context, 'Pembayaran berhasil dikonfirmasi!');
            ref.read(cartProvider.notifier).clearCart();
            context.go('/pos');
          },
          (completedOrder) {
            _showSuccessDialog(completedOrder, cashReceivedVal, changeGivenVal);
          },
        );
      } else {
        ToastHelper.showError(context, 'Gagal memproses pembayaran');
      }
    }
  }

  void _showSuccessDialog(Order order, double cashReceived, double change) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                order.invoiceNumber ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Divider(height: 24, color: AppColors.border),
              
              // Receipt details
              _buildReceiptRow('Nomor Antrean', '#${order.orderQueue}', isBold: true),
              _buildReceiptRow('Total Tagihan', _currencyFormat.format(order.grandTotal)),
              _buildReceiptRow('Uang Diterima', _currencyFormat.format(cashReceived)),
              _buildReceiptRow('Uang Kembali', _currencyFormat.format(change), color: Colors.green[700]),
              _buildReceiptRow('Metode Pembayaran', _selectedOption?.name ?? ''),
              
              const Divider(height: 24, color: AppColors.border),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ScaleImpactAnimation(
                      onTap: () async {
                        final defaultPrinterAsync = ref.read(defaultPrinterProvider);
                        defaultPrinterAsync.when(
                          data: (printer) async {
                            if (printer != null) {
                              ToastHelper.showInfo(context, 'Mencetak kuitansi...');
                              final printResult = await ref.read(printReceiptUseCaseProvider).call(
                                PrintReceiptParams(order: order, printer: printer),
                              );
                              printResult.fold(
                                (failure) => ToastHelper.showError(context, 'Gagal mencetak: ${failure.message}'),
                                (_) => ToastHelper.showSuccess(context, 'Kuitansi berhasil dicetak!'),
                              );
                            } else {
                              ToastHelper.showWarning(
                                context,
                                'Printer utama belum disetel. Hubungkan printer di menu Printer.',
                              );
                            }
                          },
                          error: (err, _) => ToastHelper.showError(context, 'Gagal membaca printer: $err'),
                          loading: () => ToastHelper.showInfo(context, 'Sedang memuat printer utama...'),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.printer, size: 16),
                            SizedBox(width: 6),
                            Text('Cetak', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScaleImpactAnimation(
                      onTap: () {
                        ref.read(cartProvider.notifier).clearCart();
                        context.pop(); // close dialog
                        context.go('/pos'); // go to POS page
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Selesai',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final paymentState = ref.watch(paymentOptionListProvider);
    final isCash = _selectedOption?.type == PaymentOptionType.cash;

    // Trigger initial default selection
    paymentState.whenData((options) {
      if (_selectedOption == null && options.isNotEmpty) {
        final activeOptions = options.where((o) => o.status == PaymentOptionStatus.active).toList();
        if (activeOptions.isNotEmpty) {
          setState(() {
            _selectedOption = activeOptions.first;
          });
        }
      }
    });

    final double change = isCash && _cashReceived >= cart.grandTotal ? (_cashReceived - cart.grandTotal) : 0.0;
    final suggestions = _getQuickCashSuggestions(cart.grandTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: paymentState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Gagal memuat metode pembayaran: $err')),
        data: (options) {
          final activeOptions = options.where((o) => o.status == PaymentOptionStatus.active).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total bill overview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL TAGIHAN',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currencyFormat.format(cart.grandTotal),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Select Payment Method
                      const Text(
                        'Pilih Metode Pembayaran',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: activeOptions.length,
                          itemBuilder: (context, index) {
                            final option = activeOptions[index];
                            final isSelected = _selectedOption?.id == option.id;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ScaleImpactAnimation(
                                onTap: () {
                                  setState(() {
                                    _selectedOption = option;
                                    if (option.type != PaymentOptionType.cash) {
                                      _cashController.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 110,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryDark : AppColors.border,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getIconData(option.icon),
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        option.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cash input form (only if selected option is cash)
                      if (isCash) ...[
                        const Text(
                          'Uang Tunai Diterima',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Masukkan jumlah uang tunai...',
                            prefixIcon: const Icon(LucideIcons.banknote, size: 24),
                            suffixIcon: _cashReceived > 0
                                ? ScaleImpactAnimation(
                                    onTap: () => _cashController.clear(),
                                    child: const Icon(LucideIcons.x, size: 18),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick cash suggestions
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final amount = suggestions[index];
                              final formatted = amount == cart.grandTotal ? 'Uang Pas' : _currencyFormat.format(amount);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ScaleImpactAnimation(
                                  onTap: () {
                                    _cashController.text = amount.toStringAsFixed(0);
                                  },
                                  child: Chip(
                                    label: Text(formatted),
                                    backgroundColor: Colors.grey[100],
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Display Change Due
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              _currencyFormat.format(change),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _cashReceived >= cart.grandTotal ? Colors.green[700] : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Non-cash details
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.info, color: Colors.blue[700], size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Pembayaran Non-Tunai', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Harap selesaikan proses transaksi di terminal EDC atau scan QRIS sebesar ${_currencyFormat.format(cart.grandTotal)} sebelum mengonfirmasi.',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ),

              // Confirm Checkout bottom bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: ScaleImpactAnimation(
                  onTap: _isProcessing || (_selectedOption?.type == PaymentOptionType.cash && _cashReceived < cart.grandTotal)
                      ? () {}
                      : () => _onConfirmPayment(cart),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isProcessing || (_selectedOption?.type == PaymentOptionType.cash && _cashReceived < cart.grandTotal)
                          ? Colors.grey[400]
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isProcessing || (_selectedOption?.type == PaymentOptionType.cash && _cashReceived < cart.grandTotal)
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Konfirmasi Pembayaran',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
