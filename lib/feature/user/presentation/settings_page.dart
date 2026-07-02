import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/impact_animation.dart';
import '../../auth/presentation/provider/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);
    final isOwner = activeUser?.role.isOwner ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: POS Settings
            _buildSectionHeader('Konfigurasi Toko & POS'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              context,
              title: 'Profil Bisnis',
              description: 'Nama toko, alamat, kontak, logo, & pajak',
              icon: LucideIcons.store,
              color: Colors.blue,
              onTap: () => context.push('/business-profile'),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              title: 'Metode Pembayaran',
              description: 'Atur opsi tunai, QRIS, debit, dll',
              icon: LucideIcons.creditCard,
              color: Colors.green[700]!,
              onTap: () => context.push('/payment-options'),
            ),
            const SizedBox(height: 24),

            // Section: Devices & Receipts
            _buildSectionHeader('Hardware & Struk'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              context,
              title: 'Printer Kasir',
              description: 'Hubungkan printer Bluetooth/USB/WiFi',
              icon: LucideIcons.printer,
              color: Colors.indigo,
              onTap: () => context.push('/settings/printers'),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              title: 'Receipt Template',
              description: 'Desain struk belanja & footer pesan',
              icon: LucideIcons.fileText,
              color: Colors.orange,
              onTap: () => context.push('/settings/receipt-template'),
            ),
            const SizedBox(height: 24),

            // Section: Access Controls (Owner Only)
            if (isOwner) ...[
              _buildSectionHeader('Karyawan & Akses'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                context,
                title: 'Kelola Pengguna / Kasir',
                description: 'Tambah, edit PIN, & atur hak akses kasir',
                icon: LucideIcons.users,
                color: Colors.purple,
                onTap: () => context.push('/settings/users'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleImpactAnimation(
      onTap: onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              // Text Content
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
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron Right
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
  }
}
