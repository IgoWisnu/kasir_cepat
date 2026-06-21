import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:kasir_cepat/feature/discount/domain/entities/discount.dart';
import 'package:kasir_cepat/feature/discount/presentation/provider/discount_provider.dart';
import 'widgets/discount_form_sheet.dart';

class DiscountListPage extends ConsumerStatefulWidget {
  const DiscountListPage({super.key});

  @override
  ConsumerState<DiscountListPage> createState() => _DiscountListPageState();
}

class _DiscountListPageState extends ConsumerState<DiscountListPage> {
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

  void _showFormSheet([Discount? discount]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DiscountFormSheet(editingDiscount: discount);
      },
    );
  }

  Future<void> _onDeleteDiscount(Discount discount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Promo'),
        content: Text('Apakah Anda yakin ingin menghapus promo "${discount.name}"?'),
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
      final success = await ref.read(discountListProvider.notifier).deleteDiscountProfile(discount.id!);
      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Promo berhasil dihapus!');
        } else {
          ToastHelper.showError(context, 'Gagal menghapus promo.');
        }
      }
    }
  }

  String _getFormattedValue(Discount discount) {
    if (discount.valueType == 'percentage') {
      final val = discount.value;
      return val % 1 == 0 ? '${val.toInt()}%' : '$val%';
    } else {
      final val = discount.value;
      if (val >= 1000) {
        final kVal = val / 1000;
        return kVal % 1 == 0 ? 'Rp ${kVal.toInt()}k' : 'Rp ${kVal}k';
      }
      return 'Rp ${val.toInt()}';
    }
  }

  String _getFormattedPeriod(Discount discount) {
    final df = DateFormat('d MMM yyyy');
    if (discount.startDate != null && discount.endDate != null) {
      return '${df.format(discount.startDate!)} - ${df.format(discount.endDate!)}';
    } else if (discount.startDate != null) {
      return 'Mulai: ${df.format(discount.startDate!)}';
    } else if (discount.endDate != null) {
      return 'S/d: ${df.format(discount.endDate!)}';
    }
    return 'Selalu Aktif';
  }

  @override
  Widget build(BuildContext context) {
    final discountListState = ref.watch(discountListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Promo & Diskon'),
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
                hintText: 'Cari nama promo...',
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
            child: discountListState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Terjadi Kesalahan: $err')),
              data: (discounts) {
                // Apply search filter locally
                final filteredDiscounts = discounts.where((discount) {
                  final matchesName = discount.name.toLowerCase().contains(_searchQuery);
                  final matchesDesc = discount.description?.toLowerCase().contains(_searchQuery) ?? false;
                  return matchesName || matchesDesc;
                }).toList();

                if (filteredDiscounts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDiscounts.length,
                  itemBuilder: (context, index) {
                    final discount = filteredDiscounts[index];
                    return _buildDiscountCard(discount);
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

  Widget _buildDiscountCard(Discount discount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            // Left Value Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: discount.isActive ? AppColors.primaryLight : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  _getFormattedValue(discount),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: discount.valueType == 'fixed' && discount.value >= 100000 ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: discount.isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          discount.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: discount.isActive ? Colors.green[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: discount.isActive ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (discount.description != null && discount.description!.isNotEmpty) ...[
                    Text(
                      discount.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Date period helper text
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        _getFormattedPeriod(discount),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                  onTap: () => _showFormSheet(discount),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                ScaleImpactAnimation(
                  onTap: () => _onDeleteDiscount(discount),
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
                LucideIcons.gift,
                color: AppColors.textLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Promo Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan tombol + di kanan bawah untuk membuat promo baru.',
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
