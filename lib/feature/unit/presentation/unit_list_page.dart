import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:kasir_cepat/feature/unit/domain/entities/unit_entity.dart';
import 'package:kasir_cepat/feature/unit/presentation/provider/unit_provider.dart';
import 'widgets/unit_form_sheet.dart';

class UnitListPage extends ConsumerStatefulWidget {
  const UnitListPage({super.key});

  @override
  ConsumerState<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends ConsumerState<UnitListPage> {
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

  void _showFormSheet([Unit? unit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UnitFormSheet(editingUnit: unit);
      },
    );
  }

  Future<void> _onDeleteUnit(Unit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Satuan'),
        content: Text('Apakah Anda yakin ingin menghapus satuan "${unit.name}"?'),
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
      final success = await ref.read(unitListProvider.notifier).deleteUnitProfile(unit.id!);
      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Satuan berhasil dihapus!');
        } else {
          ToastHelper.showError(context, 'Gagal menghapus satuan.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitListState = ref.watch(unitListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Satuan (Unit)'),
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
                hintText: 'Cari nama atau singkatan...',
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
            child: unitListState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Terjadi Kesalahan: $err')),
              data: (units) {
                // Apply search filter locally
                final filteredUnits = units.where((unit) {
                  return unit.name.toLowerCase().contains(_searchQuery) ||
                      unit.abbreviation.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUnits.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    return _buildUnitCard(unit);
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

  Widget _buildUnitCard(Unit unit) {
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
            // Left Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.layers,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unit.abbreviation,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleImpactAnimation(
                  onTap: () => _showFormSheet(unit),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                ScaleImpactAnimation(
                  onTap: () => _onDeleteUnit(unit),
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
                LucideIcons.layers,
                color: AppColors.textLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Satuan Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan tombol + di kanan bawah untuk membuat satuan baru.',
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
