import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../bussiness/presentation/provider/business_provider.dart';
import '../domain/entities/receipt_template.dart';
import 'provider/printer_provider.dart';

class ReceiptTemplatePage extends ConsumerStatefulWidget {
  const ReceiptTemplatePage({super.key});

  @override
  ConsumerState<ReceiptTemplatePage> createState() => _ReceiptTemplatePageState();
}

class _ReceiptTemplatePageState extends ConsumerState<ReceiptTemplatePage> {
  ReceiptTemplate? _localTemplate;
  bool _isInitialized = false;
  bool _hasChanges = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _initializeLocalData(ReceiptTemplate template) {
    if (_isInitialized) return;
    _localTemplate = template;
    _nameController.text = template.businessNameOverride ?? '';
    _addressController.text = template.businessAddressOverride ?? '';
    _footerController.text = template.footerText ?? '';
    _isInitialized = true;
  }

  void _onToggleChange(ReceiptTemplate Function(ReceiptTemplate) updater) {
    if (_localTemplate == null) return;
    setState(() {
      _localTemplate = updater(_localTemplate!);
      _hasChanges = true;
    });
  }

  void _onTextChange() {
    if (_localTemplate == null) return;
    final updated = _localTemplate!.copyWith(
      businessNameOverride: _nameController.text,
      businessAddressOverride: _addressController.text,
      footerText: _footerController.text,
    );
    if (updated != _localTemplate) {
      setState(() {
        _localTemplate = updated;
        _hasChanges = true;
      });
    }
  }

  Future<void> _onSave() async {
    if (_localTemplate == null) return;
    final success = await ref
        .read(receiptTemplateProvider.notifier)
        .updateReceiptTemplate(_localTemplate!);
    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(context, 'Pengaturan struk berhasil disimpan!');
        setState(() {
          _hasChanges = false;
        });
      } else {
        ToastHelper.showError(context, 'Gagal menyimpan pengaturan struk.');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text('Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(receiptTemplateProvider);
    final businessState = ref.watch(businessStateProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kustomisasi Struk'),
          leading: ScaleImpactAnimation(
            onTap: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                navigator.pop();
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            ),
          ),
          actions: [
            if (_hasChanges)
              ScaleImpactAnimation(
                onTap: _onSave,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: templateState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Terjadi kesalahan: $err', textAlign: TextAlign.center),
            ),
          ),
          data: (template) {
            _initializeLocalData(template);
            final business = businessState.valueOrNull;

            final isWide = MediaQuery.of(context).size.width > 800;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildConfigForm(),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.grey[50],
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Pratinjau Kertas Struk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildReceiptPreview(business),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReceiptPreview(business),
                  const SizedBox(height: 24),
                  _buildConfigForm(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    if (_localTemplate == null) return const SizedBox.shrink();
    final template = _localTemplate!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section Configuration
        _buildSectionHeader('Bagian Atas (Header)', LucideIcons.heading),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Tampilkan Logo Bisnis',
                  subtitle: 'Mencetak baris placeholder logo di paling atas',
                  value: template.showLogo,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showLogo: val));
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Tampilkan Nama Bisnis',
                  subtitle: 'Mencetak nama outlet usaha',
                  value: template.showBusinessName,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showBusinessName: val));
                  },
                ),
                if (template.showBusinessName) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => _onTextChange(),
                    decoration: const InputDecoration(
                      labelText: 'Override Nama Usaha (Opsional)',
                      hintText: 'Masukkan nama kustom khusus struk',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
                const Divider(),
                _buildSwitchTile(
                  title: 'Tampilkan Alamat Bisnis',
                  subtitle: 'Mencetak alamat outlet usaha',
                  value: template.showBusinessAddress,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showBusinessAddress: val));
                  },
                ),
                if (template.showBusinessAddress) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    onChanged: (_) => _onTextChange(),
                    decoration: const InputDecoration(
                      labelText: 'Override Alamat Usaha (Opsional)',
                      hintText: 'Masukkan alamat kustom khusus struk',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 2. Transaction Details Configuration
        _buildSectionHeader('Detail Transaksi', LucideIcons.fileText),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Tampilkan Nomor Invoice / ID',
                  subtitle: 'Mencetak kode invoice struk belanja',
                  value: template.showTransactionId,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showTransactionId: val));
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Tampilkan Nama Pelanggan',
                  subtitle: 'Mencetak nama pembeli jika terdaftar',
                  value: template.showCustomerName,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showCustomerName: val));
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Tampilkan Nama Kasir',
                  subtitle: 'Mencetak nama staf kasir yang melayani',
                  value: template.showCashierName,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showCashierName: val));
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 3. Item Configuration
        _buildSectionHeader('Pengaturan Baris Item', LucideIcons.package),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Tampilkan SKU Produk',
                  subtitle: 'Menampilkan SKU di bawah nama produk',
                  value: template.showProductSku,
                  onChanged: (val) {
                    _onToggleChange((t) => t.copyWith(showProductSku: val));
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 4. Footer Configuration
        _buildSectionHeader('Bagian Bawah (Footer)', LucideIcons.alignCenter),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _footerController,
                  maxLines: 3,
                  onChanged: (_) => _onTextChange(),
                  decoration: const InputDecoration(
                    labelText: 'Pesan Footer',
                    hintText: 'Tuliskan pesan terima kasih atau info media sosial...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReceiptPreview(dynamic business) {
    if (_localTemplate == null) return const SizedBox.shrink();
    final template = _localTemplate!;

    final bName = (_nameController.text.trim().isNotEmpty)
        ? _nameController.text.trim()
        : (business?.name ?? 'KASIR CEPAT');

    final bAddress = (_addressController.text.trim().isNotEmpty)
        ? _addressController.text.trim()
        : (business?.address ?? 'Jl. Raya Utama No. 123');

    final footer = (_footerController.text.trim().isNotEmpty)
        ? _footerController.text.trim()
        : (business?.footerMessage ?? 'Terima Kasih Atas Kunjungan Anda\nSimpan Bukti Pembayaran Ini');

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Jagged/Dotted top border simulation
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo
                if (template.showLogo) ...[
                  const Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.image, size: 24, color: AppColors.textLight),
                        Text(
                          '[LOGO]',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 2. Business Name
                if (template.showBusinessName) ...[
                  Text(
                    bName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                // 3. Business Address
                if (template.showBusinessAddress) ...[
                  Text(
                    bAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Separator
                const Text(
                  '================================',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),

                // 4. Details
                _buildCourierRow('Antrean', '#017'),
                if (template.showTransactionId)
                  _buildCourierRow('No. Invoice', 'INV/2026/0124'),
                _buildCourierRow('Waktu', '2026-06-23 22:50'),
                _buildCourierRow('Tipe', 'TAKEAWAY'),
                if (template.showCustomerName)
                  _buildCourierRow('Pelanggan', 'Budi Santoso'),
                if (template.showCashierName)
                  _buildCourierRow('Kasir', 'Staf Kasir'),

                const SizedBox(height: 4),
                const Text(
                  '--------------------------------',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),

                // Items
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Roti Manis Coklat',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (template.showProductSku)
                      const Text(
                        '  SKU: ROTI-002',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: Colors.black54,
                        ),
                      ),
                    _buildCourierRow('  2 x Rp 8.000', 'Rp 16.000'),
                    const SizedBox(height: 6),
                    const Text(
                      'Kopi Hitam Toraja',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (template.showProductSku)
                      const Text(
                        '  SKU: KOPI-001',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: Colors.black54,
                        ),
                      ),
                    _buildCourierRow('  1 x Rp 6.000', 'Rp 6.000'),
                  ],
                ),

                const SizedBox(height: 4),
                const Text(
                  '--------------------------------',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),

                // Summary Totals
                _buildCourierRow('Subtotal', 'Rp 22.000'),
                _buildCourierRow('Diskon', 'Rp 0'),
                _buildCourierRow('Total', 'Rp 22.000'),
                _buildCourierRow('Tunai', 'Rp 50.000'),
                _buildCourierRow('Kembali', 'Rp 28.000'),

                const SizedBox(height: 4),
                const Text(
                  '================================',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),

                // Footer lines
                ...footer.split('\n').map((line) => Text(
                      line,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    )),
                const SizedBox(height: 4),
                const Text(
                  '================================',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
          // Jagged/Dotted bottom border simulation
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
          ),
          Text(
            right,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
