import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../domain/entities/payment_option.dart';
import 'provider/payment_option_provider.dart';
import 'widgets/payment_option_form_sheet.dart';

class PaymentOptionListPage extends ConsumerStatefulWidget {
  const PaymentOptionListPage({super.key});

  @override
  ConsumerState<PaymentOptionListPage> createState() => _PaymentOptionListPageState();
}

class _PaymentOptionListPageState extends ConsumerState<PaymentOptionListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFormSheet([PaymentOption? option]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PaymentOptionFormSheet(editingOption: option);
      },
    );
  }

  Future<void> _onDeleteOption(PaymentOption option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Metode Pembayaran'),
        content: Text('Apakah Anda yakin ingin menghapus metode pembayaran "${option.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (option.id == null) return;
      final success = await ref.read(paymentOptionListProvider.notifier).deleteOption(option.id!);
      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Metode pembayaran berhasil dihapus!');
        } else {
          ToastHelper.showError(context, 'Gagal menghapus metode pembayaran.');
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final paymentListState = ref.watch(paymentOptionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Pembayaran'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari metode pembayaran...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? ScaleImpactAnimation(
                        onTap: () => _searchController.clear(),
                        child: const Icon(LucideIcons.x, size: 18),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Main list content
          Expanded(
            child: paymentListState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Terjadi Kesalahan: $err')),
              data: (options) {
                // Apply search filter locally
                final filteredOptions = options.where((option) {
                  final matchesName = option.name.toLowerCase().contains(_searchQuery);
                  final matchesDesc = option.description?.toLowerCase().contains(_searchQuery) ?? false;
                  return matchesName || matchesDesc;
                }).toList();

                if (filteredOptions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index];
                    return _buildOptionCard(option);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleImpactAnimation(
        onTap: () => _showFormSheet(),
        child: FloatingActionButton(
          onPressed: null, // Tap handler in ScaleImpactAnimation
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  Widget _buildOptionCard(PaymentOption option) {
    final isActive = option.status == PaymentOptionStatus.active;
    final isCash = option.type == PaymentOptionType.cash;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Avatar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(option.icon),
                color: isActive ? AppColors.primary : Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Info Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.textPrimary : AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCash ? Colors.green[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCash ? 'Tunai' : 'Non-Tunai',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCash ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (option.description != null && option.description!.isNotEmpty) ...[
                    Text(
                      option.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? AppColors.textSecondary : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleImpactAnimation(
                  onTap: () => _showFormSheet(option),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                ScaleImpactAnimation(
                  onTap: () => _onDeleteOption(option),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(LucideIcons.trash2, size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.creditCard,
                color: AppColors.textLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Metode Pembayaran Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan tombol + di kanan bawah untuk membuat metode pembayaran baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
