import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../domain/entities/business.dart';
import 'provider/business_provider.dart';

class BusinessProfilePage extends ConsumerStatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  ConsumerState<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends ConsumerState<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxController = TextEditingController();
  final _footerController = TextEditingController();

  // Logo state
  bool _isPresetLogo = true;
  String _selectedPresetIcon = 'store';
  Color _selectedPresetColor = AppColors.primary;
  String? _customImagePath;
  bool _isSaving = false;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _presetIcons = [
    {'name': 'store', 'icon': LucideIcons.store},
    {'name': 'coffee', 'icon': LucideIcons.coffee},
    {'name': 'utensils', 'icon': LucideIcons.utensils},
    {'name': 'shopping-bag', 'icon': LucideIcons.shoppingBag},
    {'name': 'shirt', 'icon': LucideIcons.shirt},
    {'name': 'scissors', 'icon': LucideIcons.scissors},
    {'name': 'wrench', 'icon': LucideIcons.wrench},
    {'name': 'package', 'icon': LucideIcons.package},
  ];

  final List<Color> _presetColors = [
    AppColors.primary,
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
    const Color(0xFFFF9800), // Amber/Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF4CAF50), // Green
  ];

  @override
  void initState() {
    super.initState();
  }

  void _populateForm(Business business) {
    _nameController.text = business.name;
    _emailController.text = business.email ?? '';
    _phoneController.text = business.phone ?? '';
    _addressController.text = business.address ?? '';
    _taxController.text = business.taxRate.toString();
    _footerController.text = business.footerMessage ?? '';

    final logo = business.logo;
    if (logo != null && logo.isNotEmpty) {
      if (logo.startsWith('preset:')) {
        _isPresetLogo = true;
        final parts = logo.split(':');
        if (parts.length >= 3) {
          _selectedPresetIcon = parts[1];
          final colorVal = int.tryParse(parts[2]);
          if (colorVal != null) {
            _selectedPresetColor = Color(colorVal);
          }
        }
      } else {
        _isPresetLogo = false;
        _customImagePath = logo;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Copy to app documents for local persist
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedFile = await File(pickedFile.path).copy(p.join(appDir.path, fileName));

        setState(() {
          _customImagePath = savedFile.path;
          _isPresetLogo = false;
        });
        
        if (mounted) {
          ToastHelper.showSuccess(context, 'Gambar berhasil dipilih!');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Gagal memilih gambar: $e');
      }
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Form logo value
    String? logoString;
    if (_isPresetLogo) {
      logoString = 'preset:$_selectedPresetIcon:${_selectedPresetColor.toARGB32()}';
    } else {
      logoString = _customImagePath;
    }

    final double tax = double.tryParse(_taxController.text) ?? 0.0;
    
    // Get existing business ID if available
    final currentBusiness = ref.read(businessStateProvider).value;

    final business = Business(
      id: currentBusiness?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      logo: logoString,
      taxRate: tax,
      footerMessage: _footerController.text.trim().isEmpty ? null : _footerController.text.trim(),
      createdAt: currentBusiness?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(businessStateProvider.notifier).saveBusinessProfile(business);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(context, 'Profil bisnis berhasil disimpan!');
        context.pop();
      } else {
        ToastHelper.showError(context, 'Gagal menyimpan profil bisnis.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessStateProvider);

    // Populate controllers once data is loaded asynchronously
    businessState.whenData((business) {
      if (business != null && !_isInitialized) {
        _populateForm(business);
        _isInitialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bisnis'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: businessState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Terjadi Kesalahan: $err')),
        data: (business) {
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Preview Container
                    Center(child: _buildLogoPreview()),
                    const SizedBox(height: 20),

                    // Logo Configuration Tabs
                    _buildLogoConfigSelectors(),
                    const SizedBox(height: 24),

                    // Store Details Card
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Utama',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Toko / Bisnis *',
                                prefixIcon: Icon(LucideIcons.store, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama bisnis wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Toko (Opsional)',
                                prefixIcon: Icon(LucideIcons.mail, size: 20),
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final emailExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailExp.hasMatch(val.trim())) {
                                    return 'Format email tidak valid';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'No. Telepon Toko (Opsional)',
                                prefixIcon: Icon(LucideIcons.phone, size: 20),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Toko (Opsional)',
                                prefixIcon: Icon(LucideIcons.mapPin, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Options Card (Tax, Receipt Message)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Struk & Pajak',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Pajak Toko (%)',
                                prefixIcon: Icon(LucideIcons.percent, size: 20),
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final taxVal = double.tryParse(val);
                                  if (taxVal == null || taxVal < 0) {
                                    return 'Nilai pajak harus positif';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _footerController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Pesan Footer Struk (Opsional)',
                                hintText: 'Terima kasih telah berbelanja!',
                                prefixIcon: Icon(LucideIcons.fileText, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ScaleImpactAnimation(
                      onTap: _isSaving ? () {} : _onSave,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoPreview() {
    if (_isPresetLogo) {
      IconData icon = LucideIcons.store;
      for (var item in _presetIcons) {
        if (item['name'] == _selectedPresetIcon) {
          icon = item['icon'] as IconData;
          break;
        }
      }

      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _selectedPresetColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 44,
        ),
      );
    } else {
      final hasCustomImage = _customImagePath != null && File(_customImagePath!).existsSync();
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
          image: hasCustomImage
              ? DecorationImage(
                  image: FileImage(File(_customImagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: !hasCustomImage
            ? const Icon(
                LucideIcons.image,
                color: AppColors.textLight,
                size: 40,
              )
            : null,
      );
    }
  }

  Widget _buildLogoConfigSelectors() {
    return Column(
      children: [
        // Tab-like buttons
        Row(
          children: [
            Expanded(
              child: ScaleImpactAnimation(
                onTap: () => setState(() => _isPresetLogo = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPresetLogo ? AppColors.primaryLight : Colors.white,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    border: Border.all(
                      color: _isPresetLogo ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Preset Ikon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isPresetLogo ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ScaleImpactAnimation(
                onTap: () => setState(() => _isPresetLogo = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isPresetLogo ? AppColors.primaryLight : Colors.white,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                    border: Border.all(
                      color: !_isPresetLogo ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Pilih Gambar/Foto',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !_isPresetLogo ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Settings config based on selection
        if (_isPresetLogo) ...[
          // Icons Choice Row
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pilih Ikon Toko:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetIcons.length,
              itemBuilder: (context, index) {
                final item = _presetIcons[index];
                final isSelected = _selectedPresetIcon == item['name'];
                
                return ScaleImpactAnimation(
                  onTap: () => setState(() => _selectedPresetIcon = item['name']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedPresetColor.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _selectedPresetColor : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? _selectedPresetColor : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Colors Choice Row
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pilih Warna Latar Belakang:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _presetColors.map((color) {
              final isSelected = _selectedPresetColor.toARGB32() == color.toARGB32();
              return ScaleImpactAnimation(
                onTap: () => setState(() => _selectedPresetColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ] else ...[
          // Upload Image layout
          ScaleImpactAnimation(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _customImagePath != null ? LucideIcons.refreshCw : LucideIcons.upload,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _customImagePath != null ? 'Ganti Gambar Toko' : 'Pilih Gambar dari Galeri',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }
}
