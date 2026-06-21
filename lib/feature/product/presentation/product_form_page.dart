import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../domain/entities/product.dart';
import 'provider/product_provider.dart';
import '../../categories/presentation/provider/category_provider.dart';
import '../../unit/presentation/provider/unit_provider.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? editingProduct;

  const ProductFormPage({
    super.key,
    this.editingProduct,
  });

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();

  // Selected values
  int? _selectedCategoryId;
  int? _selectedUnitId;
  String _selectedIcon = 'shoppingBag';
  bool _isTrackStock = false;
  bool _isAvailable = true;
  bool _isSaving = false;

  // Predefined icons list for product selection
  final List<Map<String, dynamic>> _predefinedIcons = [
    {'name': 'shoppingBag', 'icon': LucideIcons.shoppingBag, 'label': 'Barang'},
    {'name': 'coffee', 'icon': LucideIcons.coffee, 'label': 'Kopi'},
    {'name': 'sandwich', 'icon': LucideIcons.sandwich, 'label': 'Makanan'},
    {'name': 'glassWater', 'icon': LucideIcons.glassWater, 'label': 'Minuman'},
    {'name': 'cake', 'icon': LucideIcons.cake, 'label': 'Kue'},
    {'name': 'iceCream', 'icon': LucideIcons.iceCream, 'label': 'Es Krim'},
    {'name': 'apple', 'icon': LucideIcons.apple, 'label': 'Buah'},
    {'name': 'cookie', 'icon': LucideIcons.cookie, 'label': 'Camilan'},
    {'name': 'soup', 'icon': LucideIcons.soup, 'label': 'Sup'},
    {'name': 'pizza', 'icon': LucideIcons.pizza, 'label': 'Pizza'},
    {'name': 'gift', 'icon': LucideIcons.gift, 'label': 'Kado'},
    {'name': 'shirt', 'icon': LucideIcons.shirt, 'label': 'Pakaian'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingProduct != null) {
      final prod = widget.editingProduct!;
      _nameController.text = prod.name;
      _barcodeController.text = prod.barcode ?? '';
      _skuController.text = prod.sku ?? '';
      _priceController.text = prod.sellingPrice.toStringAsFixed(0);
      _costPriceController.text = prod.costPrice != null ? prod.costPrice!.toStringAsFixed(0) : '';
      _descController.text = prod.description ?? '';
      _stockController.text = prod.stockQuantity.toStringAsFixed(0);
      
      _selectedCategoryId = prod.categoryId;
      _selectedUnitId = prod.unitId;
      _selectedIcon = prod.imagePath ?? 'shoppingBag';
      _isTrackStock = prod.isTrackStock;
      _isAvailable = prod.status == ProductStatus.available;
    } else {
      _stockController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _descController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final sellingPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final costPriceVal = _costPriceController.text.trim().isEmpty 
        ? null 
        : double.tryParse(_costPriceController.text.trim());
    final stockQty = _isTrackStock 
        ? (double.tryParse(_stockController.text.trim()) ?? 0.0) 
        : 0.0;

    final product = Product(
      id: widget.editingProduct?.id,
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      unitId: _selectedUnitId,
      sellingPrice: sellingPrice,
      costPrice: costPriceVal,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      imagePath: _selectedIcon,
      status: _isAvailable ? ProductStatus.available : ProductStatus.unavailable,
      isTrackStock: _isTrackStock,
      stockQuantity: stockQty,
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      isActive: widget.editingProduct?.isActive ?? true,
      createdAt: widget.editingProduct?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(productListProvider.notifier).saveProductProfile(product);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingProduct != null
              ? 'Produk berhasil diperbarui!'
              : 'Produk baru berhasil disimpan!',
        );
        context.pop();
      } else {
        ToastHelper.showError(
          context,
          'Gagal menyimpan produk. Periksa kembali SKU atau input data.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryListState = ref.watch(categoryListProvider);
    final unitListState = ref.watch(unitListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editingProduct != null ? 'Edit Produk' : 'Tambah Produk Baru'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          if (!_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(LucideIcons.check, color: AppColors.primary),
                onPressed: _onSave,
              ),
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // CARD 1: Informasi Utama
                    _buildFormCard(
                      title: 'Informasi Utama',
                      icon: LucideIcons.info,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk *',
                            hintText: 'Misal: Kopi Latte Premium',
                            prefixIcon: Icon(LucideIcons.package, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama produk wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Icon Picker row
                        const Text(
                          'Pilih Icon Produk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 76,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _predefinedIcons.length,
                            itemBuilder: (context, index) {
                              final item = _predefinedIcons[index];
                              final isSelected = _selectedIcon == item['name'];

                              return Padding(
                                padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                                child: ScaleImpactAnimation(
                                  onTap: () {
                                    setState(() {
                                      _selectedIcon = item['name'] as String;
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : Colors.grey[100],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['label'] as String,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.primary : AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CARD 2: Pengaturan Harga
                    _buildFormCard(
                      title: 'Pengaturan Harga',
                      icon: LucideIcons.dollarSign,
                      children: [
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Jual *',
                            hintText: '0',
                            prefixIcon: Icon(LucideIcons.tag, size: 20),
                            prefixText: 'Rp ',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Harga jual wajib diisi';
                            }
                            if (double.tryParse(val.trim()) == null) {
                              return 'Masukkan format angka yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _costPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Beli (Opsional)',
                            hintText: '0',
                            prefixIcon: Icon(LucideIcons.shoppingBag, size: 20),
                            prefixText: 'Rp ',
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              if (double.tryParse(val.trim()) == null) {
                                return 'Masukkan format angka yang valid';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CARD 3: Klasifikasi & Kode
                    _buildFormCard(
                      title: 'Klasifikasi & Kode',
                      icon: LucideIcons.folder,
                      children: [
                        // Category Selector Dropdown
                        categoryListState.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Gagal memuat kategori: $e'),
                          data: (categories) {
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Kategori (Opsional)',
                                prefixIcon: Icon(LucideIcons.tag, size: 20),
                              ),
                              hint: const Text('Pilih Kategori'),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Tanpa Kategori'),
                                ),
                                ...categories.map((c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.name),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoryId = val;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Unit Selector Dropdown
                        unitListState.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Gagal memuat satuan: $e'),
                          data: (units) {
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedUnitId,
                              decoration: const InputDecoration(
                                labelText: 'Satuan / Unit (Opsional)',
                                prefixIcon: Icon(LucideIcons.layers, size: 20),
                              ),
                              hint: const Text('Pilih Satuan'),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Tanpa Satuan'),
                                ),
                                ...units.map((u) => DropdownMenuItem<int>(
                                      value: u.id,
                                      child: Text('${u.name} (${u.abbreviation})'),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedUnitId = val;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU Produk (Opsional)',
                            hintText: 'Misal: KOPI-LAT-001',
                            prefixIcon: Icon(LucideIcons.hash, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode Produk (Opsional)',
                            hintText: 'Misal: 8991234567',
                            prefixIcon: Icon(LucideIcons.qrCode, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CARD 4: Inventaris & Status
                    _buildFormCard(
                      title: 'Inventaris & Status',
                      icon: LucideIcons.shieldAlert,
                      children: [
                        // Status Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.checkCircle, color: AppColors.textSecondary, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Status Produk Aktif',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _isAvailable,
                              activeThumbColor: AppColors.success,
                              onChanged: (val) {
                                setState(() {
                                  _isAvailable = val;
                                });
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Track Stock Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.database, color: AppColors.textSecondary, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Lacak Stok Barang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _isTrackStock,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isTrackStock = val;
                                });
                              },
                            ),
                          ],
                        ),
                        
                        if (_isTrackStock) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Stok Saat Ini',
                              hintText: '0',
                              prefixIcon: Icon(LucideIcons.plusCircle, size: 20),
                            ),
                            validator: (val) {
                              if (_isTrackStock) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Jumlah stok wajib diisi jika melacak stok';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Masukkan format angka yang valid';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CARD 5: Deskripsi Tambahan
                    _buildFormCard(
                      title: 'Deskripsi Tambahan',
                      icon: LucideIcons.fileText,
                      children: [
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          minLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Produk (Opsional)',
                            hintText: 'Berikan deskripsi detail produk di sini...',
                            prefixIcon: Icon(LucideIcons.fileText, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SIMPAN BUTTON
                    ScaleImpactAnimation(
                      onTap: _isSaving ? () {} : _onSave,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.editingProduct != null ? 'Perbarui Produk' : 'Simpan Produk Baru',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
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
            ),
            const Divider(height: 24, color: AppColors.border),
            ...children,
          ],
        ),
      ),
    );
  }
}
