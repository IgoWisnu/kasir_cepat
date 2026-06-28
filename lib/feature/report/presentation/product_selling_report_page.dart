import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import 'provider/report_provider.dart';

class ProductSellingReportPage extends ConsumerStatefulWidget {
  const ProductSellingReportPage({super.key});

  @override
  ConsumerState<ProductSellingReportPage> createState() =>
      _ProductSellingReportPageState();
}

class _ProductSellingReportPageState extends ConsumerState<ProductSellingReportPage> {
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

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  void _setDateRange(String val) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange newRange;

    switch (val) {
      case 'hari_ini':
        newRange = DateTimeRange(
          start: today,
          end: today.add(const Duration(
              hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
        );
        break;
      case 'kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        newRange = DateTimeRange(
          start: yesterday,
          end: yesterday.add(const Duration(
              hours: 23, minutes: 59, seconds: 59, milliseconds: 999)),
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
        final currentRange = ref.read(productSellingDateRangeProvider);
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
            start: DateTime(
                range.start.year, range.start.month, range.start.day),
            end: DateTime(range.end.year, range.end.month, range.end.day, 23,
                59, 59, 999),
          );
          ref.read(productSellingDateRangeProvider.notifier).state =
              adjustedRange;
          setState(() {
            _selectedDateFilter = 'kustom';
          });
        }
        return;
      default:
        return;
    }

    ref.read(productSellingDateRangeProvider.notifier).state = newRange;
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
      case 'hari_ini':
        return 'Hari Ini';
      case 'kemarin':
        return 'Kemarin';
      case '7_hari':
        return '7 Hari Terakhir';
      case '30_hari':
        return '30 Hari Terakhir';
      default:
        return 'Hari Ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(productSellingDateRangeProvider);
    final reportAsync = ref.watch(productSellingReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Penjualan Produk',
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
          // Filter & Search Header Card
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
                    const Icon(LucideIcons.calendar,
                        size: 18, color: AppColors.textSecondary),
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

          // Main Tab Section
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Gagal memuat laporan: $err',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (report) {
                final filtered = report.items.where((item) {
                  final name = item.productName.toLowerCase();
                  final sku = (item.productSku ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      sku.contains(_searchQuery);
                }).toList();

                final topSelling =
                    filtered.where((i) => i.quantitySold > 0).toList();
                final unsold =
                    filtered.where((i) => i.quantitySold == 0).toList();

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: const TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelStyle: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(text: 'Terlaris'),
                            Tab(text: 'Tidak Terjual'),
                            Tab(text: 'Semua Produk'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProductsList(topSelling, isTopSelling: true),
                            _buildProductsList(unsold, isUnsold: true),
                            _buildProductsList(filtered),
                          ],
                        ),
                      ),
                    ],
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
          icon: const Icon(LucideIcons.chevronDown,
              size: 16, color: AppColors.textSecondary),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
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
        prefixIcon: const Icon(LucideIcons.search,
            size: 16, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isNotEmpty
            ? ScaleImpactAnimation(
                onTap: () => _searchController.clear(),
                child: const Icon(LucideIcons.x,
                    size: 16, color: AppColors.textSecondary),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildProductsList(List<dynamic> items,
      {bool isTopSelling = false, bool isUnsold = false}) {
    if (items.isEmpty) {
      return _buildEmptyState(isUnsold: isUnsold);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.refresh(productSellingReportProvider),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildProductCard(item, index + 1,
              isTopSelling: isTopSelling, isUnsold: isUnsold);
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic item, int rank,
      {bool isTopSelling = false, bool isUnsold = false}) {
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
            // Rank badge for top-selling items
            if (isTopSelling) ...[
              _buildRankBadge(rank),
              const SizedBox(width: 14),
            ] else if (isUnsold) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.package,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.package,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
            ],

            // Product Name and SKU
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
                    'SKU: ${item.productSku ?? "-"}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (!isUnsold && !isTopSelling) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Total Omset: ${_formatCurrency(item.totalSales)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Sales Amount / Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isUnsold)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Unsold',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    '${item.quantitySold.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.quantitySold > 0
                          ? Colors.teal[800]
                          : AppColors.textLight,
                    ),
                  ),
                  const Text(
                    'Unit Terjual',
                    style: TextStyle(fontSize: 9, color: AppColors.textLight),
                  ),
                  if (isTopSelling) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(item.totalSales),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    Color textColor;

    switch (rank) {
      case 1:
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        break;
      case 2:
        bgColor = Colors.blueGrey[50]!;
        textColor = Colors.blueGrey[800]!;
        break;
      case 3:
        bgColor = Colors.deepOrange[50]!;
        textColor = Colors.deepOrange[900]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isUnsold = false}) {
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
                child: Icon(
                  isUnsold ? LucideIcons.checkCircle : LucideIcons.shoppingBag,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isUnsold ? 'Semua Produk Terjual!' : 'Tidak Ada Data Penjualan',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isUnsold
                    ? 'Hebat! Seluruh produk aktif telah terjual pada periode ini.'
                    : 'Belum ada transaksi penjualan produk pada periode yang dipilih.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
