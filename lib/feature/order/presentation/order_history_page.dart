import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../domain/entities/order.dart';
import 'provider/order_provider.dart';
import 'widgets/order_detail_sheet.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Filters state
  String _selectedStatusFilter = 'semua'; // 'semua', 'completed', 'pending', 'cancelled'
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
    
    // Load orders on page opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderListProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
  }

  void _showDetailSheet(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OrderDetailSheet(order: order);
      },
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _filterByDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dt.year, dt.month, dt.day);

    switch (_selectedDateFilter) {
      case 'hari_ini':
        return _isSameDay(dt, now);
      case 'kemarin':
        final yesterday = today.subtract(const Duration(days: 1));
        return _isSameDay(dt, yesterday);
      case '7_hari':
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return orderDate.isAfter(sevenDaysAgo) || _isSameDay(orderDate, sevenDaysAgo);
      case '30_hari':
        final thirtyDaysAgo = today.subtract(const Duration(days: 30));
        return orderDate.isAfter(thirtyDaysAgo) || _isSameDay(orderDate, thirtyDaysAgo);
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

  bool _filterByStatus(Order order) {
    switch (_selectedStatusFilter) {
      case 'completed':
        return order.orderStatus == OrderStatus.completed;
      case 'pending':
        return order.paymentStatus == PaymentStatus.pending && order.orderStatus != OrderStatus.cancelled;
      case 'cancelled':
        return order.orderStatus == OrderStatus.cancelled;
      case 'semua':
      default:
        return true;
    }
  }

  String _getOrderItemsSummary(Order order) {
    if (order.items.isEmpty) return 'Tidak ada produk';
    final firstItem = order.items.first.productName;
    if (order.items.length == 1) {
      return '${order.items.first.qty.toStringAsFixed(0)}x $firstItem';
    }
    final otherCount = order.items.length - 1;
    return '${order.items.first.qty.toStringAsFixed(0)}x $firstItem + $otherCount produk lainnya';
  }

  Color _getStatusColor(OrderStatus status, PaymentStatus payment) {
    if (status == OrderStatus.cancelled) return Colors.red;
    if (payment == PaymentStatus.pending) return Colors.orange;
    return Colors.green;
  }

  String _getStatusLabel(OrderStatus status, PaymentStatus payment) {
    if (status == OrderStatus.cancelled) return 'Batal';
    if (payment == PaymentStatus.pending) return 'Pending (Belum Bayar)';
    return 'Selesai';
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
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
          // Filter Tabs & Date Dropdown Row
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

          // Horizontal Status Filter Tags
          _buildStatusFilterRow(),

          // Main list or summary view
          Expanded(
            child: orderState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
              data: (orders) {
                // Apply filters locally
                final filteredOrders = orders.where((order) {
                  // 1. Date Filter
                  if (!_filterByDate(order.createdAt)) return false;

                  // 2. Status Filter
                  if (!_filterByStatus(order)) return false;

                  // 3. Search Query
                  if (_searchQuery.isNotEmpty) {
                    final invoice = order.invoiceNumber?.toLowerCase() ?? '';
                    final customer = order.customerName?.toLowerCase() ?? '';
                    final note = order.notes?.toLowerCase() ?? '';
                    final matchesSearch = invoice.contains(_searchQuery) ||
                        customer.contains(_searchQuery) ||
                        note.contains(_searchQuery);
                    if (!matchesSearch) return false;
                  }

                  return true;
                }).toList();

                // Compute stats
                double totalSales = 0.0;
                int successCount = 0;
                int cancelCount = 0;

                for (final order in filteredOrders) {
                  if (order.orderStatus == OrderStatus.completed) {
                    totalSales += order.grandTotal;
                    successCount++;
                  } else if (order.orderStatus == OrderStatus.cancelled) {
                    cancelCount++;
                  }
                }

                return Column(
                  children: [
                    // Dynamic Stats cards
                    _buildStatsSection(totalSales, successCount, cancelCount),
                    const SizedBox(height: 8),

                    // Order List
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                ref.read(orderListProvider.notifier).loadOrders();
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  return _buildOrderCard(order);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari invoice/pelanggan...',
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

  Widget _buildStatusFilterRow() {
    final filters = [
      {'key': 'semua', 'label': 'Semua'},
      {'key': 'completed', 'label': 'Selesai'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'cancelled', 'label': 'Batal'},
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
          final isSelected = _selectedStatusFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ScaleImpactAnimation(
              onTap: () {
                setState(() {
                  _selectedStatusFilter = filter['key']!;
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

  Widget _buildStatsSection(double totalSales, int successCount, int cancelCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Omzet Penjualan',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(totalSales),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Container(height: 36, width: 1, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selesai: $successCount trx',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Batal: $cancelCount trx',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.orderStatus, order.paymentStatus);
    final statusText = _getStatusLabel(order.orderStatus, order.paymentStatus);
    final formattedTime = DateFormat('HH:mm').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(order),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Queue Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${order.orderQueue}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Order metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.invoiceNumber ?? 'Antrean #${order.orderQueue}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getOrderItemsSummary(order),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Price Total tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatCurrency(order.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textLight),
                  ],
                ),
              ],
            ),
          ),
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
                  LucideIcons.receipt,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum ada riwayat transaksi penjualan untuk filter yang Anda pilih.',
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
}
