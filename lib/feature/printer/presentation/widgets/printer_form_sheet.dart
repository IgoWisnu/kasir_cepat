import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/impact_animation.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../domain/entities/printer.dart';
import '../provider/printer_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterFormSheet extends ConsumerStatefulWidget {
  final PrinterDevice? editingPrinter;

  const PrinterFormSheet({
    super.key,
    this.editingPrinter,
  });

  @override
  ConsumerState<PrinterFormSheet> createState() => _PrinterFormSheetState();
}

class _PrinterFormSheetState extends ConsumerState<PrinterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  late PrinterConnectionType _connectionType;
  late int _paperSize;
  late bool _isDefault;
  late bool _isKitchenPrinter;
  late bool _isActive;
  bool _isSaving = false;
  bool _isScanningBluetooth = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingPrinter != null) {
      _nameController.text = widget.editingPrinter!.name;
      _addressController.text = widget.editingPrinter!.address;
      _connectionType = widget.editingPrinter!.connectionType;
      _paperSize = widget.editingPrinter!.paperSize;
      _isDefault = widget.editingPrinter!.isDefault;
      _isKitchenPrinter = widget.editingPrinter!.isKitchenPrinter;
      _isActive = widget.editingPrinter!.status == PrinterStatus.active;
    } else {
      _connectionType = PrinterConnectionType.wifi;
      _paperSize = 58;
      _isDefault = false;
      _isKitchenPrinter = false;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _startBluetoothScan() async {
    setState(() {
      _isScanningBluetooth = true;
    });

    try {
      final bool hasPermission = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!hasPermission) {
        if (mounted) {
          ToastHelper.showError(context, 'Izin Bluetooth/Lokasi tidak diberikan');
        }
        return;
      }

      final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBluetoothEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(LucideIcons.bluetooth, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Bluetooth Tidak Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Bluetooth di HP Anda dinonaktifkan.\n\nSilakan aktifkan Bluetooth Anda terlebih dahulu di pengaturan HP untuk memindai printer thermal.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Oke, Mengerti', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      final List<BluetoothInfo> results = await PrintBluetoothThermal.pairedBluetooths;
      
      if (!mounted) return;

      if (results.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(LucideIcons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('Printer Tidak Ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Tidak ditemukan printer Bluetooth yang terhubung.\n\nLangkah Penyelesaian:\n1. Pastikan printer thermal Anda sudah menyala.\n2. Buka Pengaturan Bluetooth HP Anda, cari printer thermal, lalu pasangkan/hubungkan (pair) terlebih dahulu.\n3. Kembali ke aplikasi Kasir Cepat lalu coba pindai kembali.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Oke, Mengerti', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      final selectedDevice = await showDialog<BluetoothInfo>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(LucideIcons.bluetooth, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Pindai Printer BT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final dev = results[index];
                  final String name = dev.name.isEmpty ? 'Perangkat Tidak Dikenal' : dev.name;
                  return ListTile(
                    leading: const Icon(LucideIcons.printer, color: AppColors.primary),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text('MAC: ${dev.macAdress}', style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.of(context).pop(dev);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              )
            ],
          );
        },
      );

      if (selectedDevice != null && mounted) {
        setState(() {
          final String name = selectedDevice.name.isEmpty ? 'Printer BT' : selectedDevice.name;
          _nameController.text = name;
          _addressController.text = selectedDevice.macAdress;
          _paperSize = 58; // Default paper size for BT printers
        });
        ToastHelper.showSuccess(context, 'Perangkat Bluetooth berhasil dipilih!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Gagal memindai: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningBluetooth = false;
        });
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

    final printer = PrinterDevice(
      id: widget.editingPrinter?.id,
      name: _nameController.text.trim(),
      connectionType: _connectionType,
      address: _addressController.text.trim(),
      paperSize: _paperSize,
      isDefault: _isDefault,
      isKitchenPrinter: _isKitchenPrinter,
      status: _isActive ? PrinterStatus.active : PrinterStatus.inactive,
    );

    final success = await ref.read(printerListProvider.notifier).savePrinterDevice(printer);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastHelper.showSuccess(
          context,
          widget.editingPrinter != null
              ? 'Printer berhasil diperbarui!'
              : 'Printer baru berhasil ditambahkan!',
        );
        
        // If set as default, load the default printer as well
        if (_isDefault && printer.id != null) {
          await ref.read(defaultPrinterProvider.notifier).setAsDefault(printer.id!);
        } else if (_isDefault && widget.editingPrinter == null) {
          // Note: for a new printer, we set it as default afterwards.
          // In SQLite the insert returns the new id, but let's reload default printer in case.
          ref.read(defaultPrinterProvider.notifier).loadDefaultPrinter();
        }
        
        if (mounted) {
          context.pop();
        }
      } else {
        if (mounted) {
          ToastHelper.showError(
            context,
            'Gagal menyimpan data printer.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editingPrinter != null ? 'Edit Printer' : 'Tambah Printer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  ScaleImpactAnimation(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),

              // Name Input
              TextFormField(
                controller: _nameController,
                autofocus: widget.editingPrinter == null,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Printer *',
                  hintText: 'Misal: Printer Kasir, Printer Dapur',
                  prefixIcon: Icon(LucideIcons.printer, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama printer wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Connection Type Dropdown
              DropdownButtonFormField<PrinterConnectionType>(
                initialValue: _connectionType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Koneksi *',
                  prefixIcon: Icon(LucideIcons.link, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PrinterConnectionType.wifi,
                    child: Text('Wi-Fi / Network LAN'),
                  ),
                  DropdownMenuItem(
                    value: PrinterConnectionType.bluetooth,
                    child: Text('Bluetooth'),
                  ),
                  DropdownMenuItem(
                    value: PrinterConnectionType.usb,
                    child: Text('USB Port'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _connectionType = val;
                      // Update hint text or clean address controller if needed
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Address Input (IP Address / MAC Address / Port name)
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _connectionType == PrinterConnectionType.wifi
                      ? 'Alamat IP (Wi-Fi) *'
                      : _connectionType == PrinterConnectionType.bluetooth
                          ? 'Alamat MAC (Bluetooth) *'
                          : 'Port USB / ID *',
                  hintText: _connectionType == PrinterConnectionType.wifi
                      ? 'Misal: 192.168.1.100'
                      : _connectionType == PrinterConnectionType.bluetooth
                          ? 'Misal: 00:11:22:33:FF:EE'
                          : 'Misal: USB001, /dev/usb/lp0',
                  prefixIcon: Icon(
                    _connectionType == PrinterConnectionType.wifi
                        ? LucideIcons.wifi
                        : _connectionType == PrinterConnectionType.bluetooth
                            ? LucideIcons.bluetooth
                            : LucideIcons.usb,
                    size: 20,
                  ),
                  suffixIcon: _connectionType == PrinterConnectionType.bluetooth
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ScaleImpactAnimation(
                                onTap: _isScanningBluetooth ? () {} : _startBluetoothScan,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isScanningBluetooth ? LucideIcons.loader : LucideIcons.search,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Scan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alamat koneksi printer wajib diisi';
                  }
                  if (_connectionType == PrinterConnectionType.wifi) {
                    // Basic IP format check
                    final ipRegExp = RegExp(
                      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
                    );
                    if (!ipRegExp.hasMatch(val.trim())) {
                      return 'Masukkan alamat IP yang valid';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Paper Size Selector
              Text(
                'Ukuran Kertas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ScaleImpactAnimation(
                      onTap: () {
                        setState(() {
                          _paperSize = 58;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _paperSize == 58 ? AppColors.primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paperSize == 58 ? AppColors.primaryDark : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '58 mm',
                          style: TextStyle(
                            color: _paperSize == 58 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScaleImpactAnimation(
                      onTap: () {
                        setState(() {
                          _paperSize = 80;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _paperSize == 80 ? AppColors.primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paperSize == 80 ? AppColors.primaryDark : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '80 mm',
                          style: TextStyle(
                            color: _paperSize == 80 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Switches Group
              SwitchListTile(
                title: const Text(
                  'Printer Utama (Default)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Gunakan printer ini otomatis untuk cetak kuitansi penjualan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                value: _isDefault,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 16),
              SwitchListTile(
                title: const Text(
                  'Printer Dapur',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Cetak pesanan baru ke dapur untuk penyiapan makanan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                value: _isKitchenPrinter,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isKitchenPrinter = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 16),
              SwitchListTile(
                title: const Text(
                  'Status Aktif',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Nonaktifkan jika printer sedang diperbaiki atau tidak digunakan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 28),

              // Save button
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
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.editingPrinter != null ? 'Simpan Perubahan' : 'Hubungkan Printer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
