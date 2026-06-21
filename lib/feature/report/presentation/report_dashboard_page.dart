import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import 'provider/report_provider.dart';

class ReportDashboardPage extends ConsumerWidget {
  const ReportDashboardPage({super.key});

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayReport = ref.watch(todaySalesReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Bisnis',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today Overview Header
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // KPI Stats Grid
              todayReport.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Gagal memuat ringkasan: $err'),
                  ),
                ),
                data: (report) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Total Penjualan (Omset)',
                            value: _formatCurrency(report.totalSales),
                            icon: LucideIcons.coins,
                            color: Colors.green[700]!,
                            bgColor: Colors.green[50]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Laba Kotor',
                            value: _formatCurrency(report.grossProfit),
                            icon: LucideIcons.trendingUp,
                            color: Colors.teal[700]!,
                            bgColor: Colors.teal[50]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Transaksi Sukses',
                            value: '${report.transactionCount} Transaksi',
                            icon: LucideIcons.receipt,
                            color: Colors.blue[700]!,
                            bgColor: Colors.blue[50]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Total Diskon',
                            value: _formatCurrency(report.totalDiscounts),
                            icon: LucideIcons.percent,
                            color: Colors.purple[700]!,
                            bgColor: Colors.purple[50]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Menu Options Header
              const Text(
                'Menu Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Consolidated Report Menu Cards
              _buildNavigationMenuCard(
                context,
                title: 'Laporan Penjualan Detail',
                description: 'Pendapatan, HPP (COGS), Margin Profit, breakdown kategori terlaris & metode pembayaran.',
                icon: LucideIcons.barChart3,
                color: Colors.teal[600]!,
                route: '/reports/sales',
              ),
              _buildNavigationMenuCard(
                context,
                title: 'Laporan Per Shift',
                description: 'Detail performa cashier shift, modal laci uang, pencatatan kas riil, dan selisih kas.',
                icon: LucideIcons.users2,
                color: Colors.orange[700]!,
                route: '/reports/shifts',
              ),
              _buildNavigationMenuCard(
                context,
                title: 'Laporan Mutasi Stok',
                description: 'Catatan komparatif pergerakan stok keluar masuk akibat penjualan, restock, opname, dan koreksi.',
                icon: LucideIcons.package2,
                color: Colors.blue[600]!,
                route: '/reports/stock-movements',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: ScaleImpactAnimation(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon card
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Description and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow right icon
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
