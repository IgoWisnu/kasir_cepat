import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../domain/entities/printer.dart';
import 'provider/printer_provider.dart';
import 'widgets/printer_form_sheet.dart';

class PrinterListPage extends ConsumerStatefulWidget {
  const PrinterListPage({super.key});

  @override
  ConsumerState<PrinterListPage> createState() => _PrinterListPageState();
}

class _PrinterListPageState extends ConsumerState<PrinterListPage> {
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

  void _showFormSheet([PrinterDevice? printer]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PrinterFormSheet(editingPrinter: printer);
      },
    );
  }

  Future<void> _onDeletePrinter(PrinterDevice printer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Printer'),
        content: Text('Apakah Anda yakin ingin menghapus printer "${printer.name}"?'),
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
      if (printer.id == null) return;
      final success = await ref.read(printerListProvider.notifier).deletePrinterDevice(printer.id!);
      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Printer berhasil dihapus!');
          ref.read(defaultPrinterProvider.notifier).loadDefaultPrinter();
        } else {
          ToastHelper.showError(context, 'Gagal menghapus printer.');
        }
      }
    }
  }

  Future<void> _setAsDefaultPrinter(PrinterDevice printer) async {
    if (printer.id == null) return;
    if (printer.isDefault) return; // already default

    final success = await ref.read(defaultPrinterProvider.notifier).setAsDefault(printer.id!);
    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(context, '"${printer.name}" disetel sebagai printer utama!');
        // Reload printer list to update the visual flags
        ref.read(printerListProvider.notifier).loadPrinters();
      } else {
        ToastHelper.showError(context, 'Gagal menyetel printer utama.');
      }
    }
  }

  Future<void> _onTestPrint(PrinterDevice printer) async {
    ToastHelper.showInfo(context, 'Mencetak halaman uji coba...');
    final result = await ref.read(printTestPageUseCaseProvider).call(printer);
    if (mounted) {
      result.fold(
        (failure) => ToastHelper.showError(context, 'Gagal cetak uji coba: ${failure.message}'),
        (_) => ToastHelper.showSuccess(context, 'Cetak uji coba berhasil!'),
      );
    }
  }

  IconData _getConnectionIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.wifi:
        return LucideIcons.wifi;
      case PrinterConnectionType.bluetooth:
        return LucideIcons.bluetooth;
      case PrinterConnectionType.usb:
        return LucideIcons.usb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerListState = ref.watch(printerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Printer'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          ScaleImpactAnimation(
            onTap: () => context.push('/settings/receipt-template'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(LucideIcons.receipt, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search/Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari printer...',
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
            child: printerListState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Terjadi Kesalahan: $err', textAlign: TextAlign.center),
                ),
              ),
              data: (printers) {
                final filtered = printers.where((printer) {
                  return printer.name.toLowerCase().contains(_searchQuery) ||
                      printer.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.read(printerListProvider.notifier).loadPrinters();
                    ref.read(defaultPrinterProvider.notifier).loadDefaultPrinter();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final printer = filtered[index];
                      return _buildPrinterCard(printer);
                    },
                  ),
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

  Widget _buildPrinterCard(PrinterDevice printer) {
    final isActive = printer.status == PrinterStatus.active;
    final isDefault = printer.isDefault;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDefault
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
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
            // Left Connection Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDefault
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getConnectionIcon(printer.connectionType),
                color: isDefault ? AppColors.primary : Colors.grey[500],
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
                          printer.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.textPrimary : AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Paper Size Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${printer.paperSize}mm',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alamat: ${printer.address}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppColors.textSecondary : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Active status
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
                      
                      // Default Printer Badge
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.check, size: 10, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Utama',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Kitchen Printer Badge
                      if (printer.isKitchenPrinter)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.utensils, size: 10, color: Colors.orange[700]),
                              const SizedBox(width: 3),
                              Text(
                                'Dapur',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions (Edit, Delete, Set Default)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Test Print Button
                    ScaleImpactAnimation(
                      onTap: () => _onTestPrint(printer),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(LucideIcons.printer, size: 18, color: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Edit Button
                    ScaleImpactAnimation(
                      onTap: () => _showFormSheet(printer),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete Button
                    ScaleImpactAnimation(
                      onTap: () => _onDeletePrinter(printer),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(LucideIcons.trash2, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (!isDefault && isActive) ...[
                  const SizedBox(height: 8),
                  ScaleImpactAnimation(
                    onTap: () => _setAsDefaultPrinter(printer),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.star, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Jadikan Utama',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
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
                  LucideIcons.printer,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Printer Belum Terhubung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungkan thermal printer Anda (Wi-Fi, Bluetooth, atau USB) untuk mencetak struk transaksi penjualan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ScaleImpactAnimation(
                onTap: () => _showFormSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Tambah Printer',
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
            ],
          ),
        ),
      ),
    );
  }
}
