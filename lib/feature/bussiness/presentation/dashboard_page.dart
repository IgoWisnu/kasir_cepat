import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../core/utils/impact_animation.dart';
import '../domain/entities/business.dart';
import 'provider/business_provider.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../../shift/presentation/provider/shift_provider.dart';
import '../../shift/presentation/widgets/open_shift_sheet.dart';
import '../../shift/presentation/widgets/end_shift_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  double _todaySales = 0.0;
  int _todayTrxCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get today's completed transactions and sales
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayData = await db.rawQuery(
        "SELECT COUNT(*) as count, SUM(grand_total) as total FROM orders WHERE order_status = 'completed' AND created_at LIKE ?",
        ['$todayStr%'],
      );
      final todayTrx = Sqflite.firstIntValue(todayData) ?? 0;
      final todaySls = (todayData.first['total'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _todaySales = todaySls;
        _todayTrxCount = todayTrx;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Gagal memuat ringkasan data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);
    final shiftState = ref.watch(shiftProvider);
    final openShiftPrompted = ref.watch(openShiftPromptedProvider);

    if (activeUser != null &&
        shiftState is AsyncData &&
        shiftState.value == null &&
        !openShiftPrompted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(openShiftPromptedProvider) == false) {
          ref.read(openShiftPromptedProvider.notifier).state = true;
          OpenShiftSheet.show(context);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile & Business
                _buildHeader(),
                const SizedBox(height: 16),

                // Business Card (business name + tenant icon)
                _buildBusinessCard(),
                const SizedBox(height: 20),

                // Dashboard stats (sales and transaction today) in small card
                _buildTodayStatsCards(),
                const SizedBox(height: 24),

                // Shift Status Card
                _buildShiftStatusCard(),
                const SizedBox(height: 24),

                // Menu Section title
                Text(
                  'Menu Utama',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Portrait Grid Menu
                _buildMenuGrid(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessAvatar(
    AsyncValue<Business?> businessState, {
    double size = 42,
    double iconSize = 20,
  }) {
    return businessState.maybeWhen(
      data: (business) {
        if (business == null ||
            business.logo == null ||
            business.logo!.isEmpty) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.store,
              color: AppColors.primary,
              size: iconSize,
            ),
          );
        }

        final logo = business.logo!;
        if (logo.startsWith('preset:')) {
          final parts = logo.split(':');
          IconData icon = LucideIcons.store;
          Color color = AppColors.primary;
          if (parts.length >= 3) {
            final iconName = parts[1];
            final colorVal = int.tryParse(parts[2]);
            if (colorVal != null) color = Color(colorVal);

            switch (iconName) {
              case 'store':
                icon = LucideIcons.store;
                break;
              case 'coffee':
                icon = LucideIcons.coffee;
                break;
              case 'utensils':
                icon = LucideIcons.utensils;
                break;
              case 'shopping-bag':
                icon = LucideIcons.shoppingBag;
                break;
              case 'shirt':
                icon = LucideIcons.shirt;
                break;
              case 'scissors':
                icon = LucideIcons.scissors;
                break;
              case 'wrench':
                icon = LucideIcons.wrench;
                break;
              case 'package':
                icon = LucideIcons.package;
                break;
            }
          }
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: iconSize),
          );
        } else {
          final file = File(logo);
          if (file.existsSync()) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
        }
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.store,
            color: AppColors.primary,
            size: iconSize,
          ),
        );
      },
      orElse: () => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.store,
          color: AppColors.primary,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeUser = ref.watch(activeUserProvider);
    final cashierName = activeUser?['name'] ?? 'Kasir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Bertugas,',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          cashierName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCard() {
    final businessState = ref.watch(businessStateProvider);
    return businessState.maybeWhen(
      data: (business) {
        final String name = business?.name ?? 'Kasir Cepat POS';
        final String? phone = business?.phone;
        final String? address = business?.address;

        return ScaleImpactAnimation(
          onTap: () {
            context.push('/business-profile');
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                    ),
                    child: _buildBusinessAvatar(
                      businessState,
                      size: 54,
                      iconSize: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (address != null && address.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        if (phone != null && phone.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.phone,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'Tap untuk atur profil bisnis',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildTodayStatsCards() {
    return Row(
      children: [
        // 1. Sales Today Card
        Expanded(
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
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.trendingUp,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Omzet Hari Ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_todaySales),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 2. Transactions Today Card
        Expanded(
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
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.receipt,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaksi Hari Ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_todayTrxCount Trx',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftStatusCard() {
    final shiftState = ref.watch(shiftProvider);
    final activeUser = ref.watch(activeUserProvider);
    final cashierName = activeUser?['name'] ?? 'Kasir';

    return shiftState.when(
      loading: () => Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Text(
          'Gagal memuat status shift: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (shift) {
        if (shift == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Shift Belum Aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Transaksi Anda tidak akan dikelompokkan ke dalam shift. Silakan buka shift terlebih dahulu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ScaleImpactAnimation(
                  onTap: () {
                    OpenShiftSheet.show(context);
                  },
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      LucideIcons.play,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Mulai Shift Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final formattedTime = DateFormat('HH:mm').format(shift.startTime);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Shift Sedang Aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mulai $formattedTime',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modal Awal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(shift.cashStart),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Kasir',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cashierName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ScaleImpactAnimation(
                onTap: () {
                  EndShiftSheet.show(context);
                },
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(
                    LucideIcons.stopCircle,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Akhiri Shift',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  Widget _buildMenuGrid(BuildContext context) {
    // 3-column app-icon style grid with text labels below the cards
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.88,
      children: [
        _buildMenuItem(
          context,
          title: 'POS Penjualan',
          icon: LucideIcons.shoppingCart,
          color: AppColors.primary,
          route: '/pos',
          badgeText: 'Kasir',
        ),
        _buildMenuItem(
          context,
          title: 'Daftar Produk',
          icon: LucideIcons.package,
          color: Colors.indigo,
          route: '/products',
        ),
        _buildMenuItem(
          context,
          title: 'Kategori',
          icon: LucideIcons.tag,
          color: Colors.orange,
          route: '/categories',
        ),
        _buildMenuItem(
          context,
          title: 'Satuan (Unit)',
          icon: LucideIcons.layers,
          color: Colors.teal,
          route: '/units',
        ),
        _buildMenuItem(
          context,
          title: 'Kelola Stok',
          icon: LucideIcons.trendingUp,
          color: Colors.blueGrey,
          route: '/stock',
        ),
        _buildMenuItem(
          context,
          title: 'Mutasi Stok',
          icon: LucideIcons.arrowLeftRight,
          color: Colors.cyan[700]!,
          route: '/stock/movements',
        ),
        _buildMenuItem(
          context,
          title: 'Diskon & Promo',
          icon: LucideIcons.percent,
          color: Colors.purple,
          route: '/discounts',
        ),
        _buildMenuItem(
          context,
          title: 'Riwayat Penjualan',
          icon: LucideIcons.receipt,
          color: Colors.brown,
          route: '/transactions',
        ),
        _buildMenuItem(
          context,
          title: 'Metode Pembayaran',
          icon: LucideIcons.creditCard,
          color: Colors.green[700]!,
          route: '/payment-options',
        ),
        _buildMenuItem(
          context,
          title: 'Riwayat Shift',
          icon: LucideIcons.history,
          color: Colors.teal[800]!,
          route: '/shifts',
        ),
        _buildMenuItem(
          context,
          title: 'Laporan Bisnis',
          icon: LucideIcons.barChart2,
          color: Colors.purple[700]!,
          route: '/reports',
        ),
        _buildMenuItem(
          context,
          title: 'Pengaturan & Printer',
          icon: LucideIcons.settings,
          color: Colors.blue,
          route: '/settings',
        ),
        _buildMenuItem(
          context,
          title: 'Keluar',
          icon: LucideIcons.logOut,
          color: Colors.grey[700]!,
          route: '/login',
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
    String? badgeText,
    bool isLogout = false,
  }) {
    return ScaleImpactAnimation(
      onTap: () {
        if (isLogout) {
          ref.read(activeUserProvider.notifier).clearUser();
          ref.read(openShiftPromptedProvider.notifier).state = false;
          ToastHelper.showInfo(context, 'Keluar dari akun kasir');
          context.go(route);
        } else {
          context.push(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              if (badgeText != null)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
