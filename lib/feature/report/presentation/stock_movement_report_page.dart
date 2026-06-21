import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import 'provider/report_provider.dart';

class StockMovementReportPage extends ConsumerStatefulWidget {
  const StockMovementReportPage({super.key});

  @override
  ConsumerState<StockMovementReportPage> createState() => _StockMovementReportPageState();
}

class _StockMovementReportPageState extends ConsumerState<StockMovementReportPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDateFilter = 'hari_ini'; // 'hari_ini', 'kemarin', '7_hari', '30_hari', 'kustom'

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

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'sale': return 'Penjualan';
      case 'restock': return 'Restok';
      case 'opname': return 'Opname';
      case 'adjustment': return 'Koreksi';
      case 'stock_in': return 'Stok Masuk';
      case 'stock_out': return 'Stok Keluar';
      default: return type.toUpperCase();
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'restock':
      case 'stock_in':
        return Colors.green;
      case 'sale':
      case 'stock_out':
        return Colors.red;
      case 'opname':
        return Colors.blue;
      case 'adjustment':
      default:
        return Colors.orange;
    }
  }

  void _setDateRange(String val) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange newRange;

    switch (val) {
      case 'hari_ini':
        newRange = DateTimeRange(
          start: today,
          end: today.add(const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        );
        break;
      case 'kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        newRange = DateTimeRange(
          start: yesterday,
          end: yesterday.add(const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        );
        break;
      case '7_hari':
        newRange = DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case '30_hari':
        newRange = DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case 'kustom':
        final currentRange = ref.read(reportStockMovementDateRangeProvider);
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: currentRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          final adjustedRange = DateTimeRange(
            start: DateTime(range.start.year, range.start.month, range.start.day),
            end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999),
          );
          ref.read(reportStockMovementDateRangeProvider.notifier).state = adjustedRange;
          setState(() {
            _selectedDateFilter = 'kustom';
          });
        }
        return;
      default:
        return;
    }

    ref.read(reportStockMovementDateRangeProvider.notifier).state = newRange;
    setState(() {
      _selectedDateFilter = val;
    });
  }

  String _getDateFilterLabel(DateTimeRange range) {
    if (_selectedDateFilter == 'kustom') {
      final start = DateFormat('dd/MM/yyyy').format(range.start);
      final end = DateFormat('dd/MM/yyyy').format(range.end);
      return '$start - $end';
    }
    switch (_selectedDateFilter) {
      case 'hari_ini': return 'Hari Ini';
      case 'kemarin': return 'Kemarin';
      case '7_hari': return '7 Hari Terakhir';
      case '30_hari': return '30 Hari Terakhir';
      default: return 'Hari Ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(reportStockMovementDateRangeProvider);
    final movementsAsync = ref.watch(reportStockMovementReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Mutasi Stok',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDateFilterLabel(dateRange),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildFilterDropdown(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
              ],
            ),
          ),

          // Movements list
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Gagal memuat mutasi stok: $err', textAlign: TextAlign.center),
                ),
              ),
              data: (movements) {
                final filtered = movements.where((item) {
                  final name = item.productName.toLowerCase();
                  final sku = item.productSku.toLowerCase();
                  return name.contains(_searchQuery) || sku.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.refresh(reportStockMovementReportProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildMovementCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDateFilter,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'hari_ini', child: Text('Hari Ini')),
            DropdownMenuItem(value: 'kemarin', child: Text('Kemarin')),
            DropdownMenuItem(value: '7_hari', child: Text('7 Hari')),
            DropdownMenuItem(value: '30_hari', child: Text('30 Hari')),
            DropdownMenuItem(value: 'kustom', child: Text('Kustom...')),
          ],
          onChanged: (val) {
            if (val != null) {
              _setDateRange(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Cari produk berdasarkan nama atau SKU...',
        prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isNotEmpty
            ? ScaleImpactAnimation(
                onTap: () => _searchController.clear(),
                child: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildMovementCard(dynamic item) {
    final isSaleOrOut = item.type == 'sale' || item.type == 'stock_out';
    final qtyPrefix = isSaleOrOut ? '-' : '+';
    final qtyColor = isSaleOrOut ? Colors.red[700] : Colors.green[700];
    final typeColor = _getTransactionTypeColor(item.type);
    final typeLabel = _getTransactionTypeLabel(item.type);

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
          children: [
            // Directional icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSaleOrOut ? Colors.red[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSaleOrOut ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                color: isSaleOrOut ? Colors.red[700] : Colors.green[700],
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.productSku}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.reference != null && item.reference.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ref: ${item.reference}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.notes != null && item.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Memo: ${item.notes}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Quantity column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$qtyPrefix${item.quantity.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: qtyColor,
                  ),
                ),
                const Text(
                  'Unit',
                  style: TextStyle(fontSize: 9, color: AppColors.textLight),
                ),
              ],
            ),
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
                  LucideIcons.packagePlus,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Mutasi Stok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum terdeteksi adanya mutasi keluar masuk barang pada rentang tanggal yang dipilih.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
