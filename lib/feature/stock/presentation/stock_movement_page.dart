import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../domain/entities/stock_transaction.dart';
import 'provider/stock_provider.dart';

class StockMovementPage extends ConsumerStatefulWidget {
  const StockMovementPage({super.key});

  @override
  ConsumerState<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends ConsumerState<StockMovementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'semua'; // 'semua', 'sale', 'restock', 'opname', 'adjustment'
  String _selectedDateFilter = 'hari_ini'; // 'hari_ini', 'kemarin', '7_hari', '30_hari', 'kustom', 'semua_waktu'
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockMovementProvider.notifier).loadMovements();
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

  String _getTransactionTypeLabel(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn:
        return 'Stok Masuk';
      case StockTransactionType.stockOut:
        return 'Stok Keluar';
      case StockTransactionType.sale:
        return 'Penjualan';
      case StockTransactionType.adjustment:
        return 'Koreksi';
      case StockTransactionType.restock:
        return 'Restok';
      case StockTransactionType.opname:
        return 'Opname';
    }
  }

  Color _getTransactionTypeColor(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.restock:
      case StockTransactionType.stockIn:
        return Colors.green;
      case StockTransactionType.sale:
      case StockTransactionType.stockOut:
        return Colors.red;
      case StockTransactionType.opname:
        return Colors.blue;
      case StockTransactionType.adjustment:
        return Colors.orange;
    }
  }

  bool _filterByType(StockTransactionType type) {
    if (_selectedTypeFilter == 'semua') return true;
    return type.name == _selectedTypeFilter;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _filterByDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(dt.year, dt.month, dt.day);

    switch (_selectedDateFilter) {
      case 'hari_ini':
        return _isSameDay(dt, now);
      case 'kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        return _isSameDay(dt, yesterday);
      case '7_hari':
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return txDate.isAfter(sevenDaysAgo) || _isSameDay(txDate, sevenDaysAgo);
      case '30_hari':
        final thirtyDaysAgo = today.subtract(const Duration(days: 30));
        return txDate.isAfter(thirtyDaysAgo) || _isSameDay(txDate, thirtyDaysAgo);
      case 'kustom':
        if (_customDateRange == null) return true;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59, 999, 999);
        return !dt.isBefore(start) && !dt.isAfter(end);
      case 'semua_waktu':
      default:
        return true;
    }
  }

  String _getDateFilterLabel() {
    if (_selectedDateFilter == 'kustom' && _customDateRange != null) {
      final start = DateFormat('dd/MM').format(_customDateRange!.start);
      final end = DateFormat('dd/MM').format(_customDateRange!.end);
      return '$start - $end';
    }
    switch (_selectedDateFilter) {
      case 'hari_ini': return 'Hari Ini';
      case 'kemarin': return 'Kemarin';
      case '7_hari': return '7 Hari';
      case '30_hari': return '30 Hari';
      case 'kustom': return 'Kustom';
      case 'semua_waktu': default: return 'Semua';
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementState = ref.watch(stockMovementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutasi & Pergerakan Stok'),
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
          // Search & Date Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                _buildDateDropdown(),
              ],
            ),
          ),

          // Horizontal Filter Row
          _buildFilterTabsRow(),

          // Transactions List
          Expanded(
            child: movementState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
              data: (movements) {
                final filtered = movements.where((tx) {
                  final productName = tx.productName?.toLowerCase() ?? '';
                  final matchesSearch = productName.contains(_searchQuery);
                  final matchesType = _filterByType(tx.type);
                  final matchesDate = _filterByDate(tx.createdAt);
                  return matchesSearch && matchesType && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.read(stockMovementProvider.notifier).loadMovements();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _buildMovementCard(tx);
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

  Widget _buildFilterTabsRow() {
    final filters = [
      {'key': 'semua', 'label': 'Semua'},
      {'key': 'sale', 'label': 'Penjualan'},
      {'key': 'restock', 'label': 'Restok'},
      {'key': 'opname', 'label': 'Opname'},
      {'key': 'adjustment', 'label': 'Koreksi'},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedTypeFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ScaleImpactAnimation(
              onTap: () {
                setState(() {
                  _selectedTypeFilter = filter['key']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDark : Colors.transparent,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovementCard(StockTransaction tx) {
    final isPositive = tx.quantity > 0;
    final typeColor = _getTransactionTypeColor(tx.type);
    final typeLabel = _getTransactionTypeLabel(tx.type);

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
            // Left icon showing directional indicator (in or out)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                color: isPositive ? Colors.green[700] : Colors.red[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Metadata info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.productName ?? 'Produk ID: ${tx.productId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(tx.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Type tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // Notes description
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tx.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Quantity changed amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isPositive ? "+" : ""}${tx.quantity.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPositive ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                const Text(
                  'Unit',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
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
                  LucideIcons.arrowLeftRight,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Riwayat Mutasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum terdeteksi adanya riwayat pergerakan stok untuk produk ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama produk...',
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        suffixIcon: _searchQuery.isNotEmpty
            ? ScaleImpactAnimation(
                onTap: () => _searchController.clear(),
                child: const Icon(LucideIcons.x, size: 16),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildDateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDateFilter,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          selectedItemBuilder: (context) {
            return [
              'hari_ini', 'kemarin', '7_hari', '30_hari', 'kustom', 'semua_waktu'
            ].map((val) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(_getDateFilterLabel()),
              );
            }).toList();
          },
          items: const [
            DropdownMenuItem(value: 'hari_ini', child: Text('Hari Ini')),
            DropdownMenuItem(value: 'kemarin', child: Text('Kemarin')),
            DropdownMenuItem(value: '7_hari', child: Text('7 Hari')),
            DropdownMenuItem(value: '30_hari', child: Text('30 Hari')),
            DropdownMenuItem(value: 'kustom', child: Text('Kustom...')),
            DropdownMenuItem(value: 'semua_waktu', child: Text('Semua')),
          ],
          onChanged: (val) async {
            if (val == 'kustom') {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _customDateRange ?? DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                ),
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
                setState(() {
                  _customDateRange = range;
                  _selectedDateFilter = 'kustom';
                });
              }
            } else {
              setState(() {
                _selectedDateFilter = val!;
              });
            }
          },
        ),
      ),
    );
  }
}
