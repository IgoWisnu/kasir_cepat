import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../core/utils/impact_animation.dart';
import 'provider/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  List<Map<String, dynamic>> _cashiers = [];
  Map<String, dynamic>? _selectedCashier;
  String _pin = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final users = await db.query(
        'users',
        where: 'is_active = ?',
        whereArgs: [1],
      );
      setState(() {
        _cashiers = users;
        if (users.isNotEmpty) {
          _selectedCashier = users.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Gagal memuat data kasir: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPinKeyPress(String value) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += value;
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onPinDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    if (_selectedCashier == null) return;

    final correctPin = _selectedCashier!['pin'].toString();
    final cashierName = _selectedCashier!['name'].toString();

    // Small delay to let the user see the 4th dot filled
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      if (_pin == correctPin) {
        ref.read(activeUserProvider.notifier).setUser(_selectedCashier!);
        ToastHelper.showSuccess(
          context,
          'Selamat datang kembali, $cashierName!',
        );
        context.go('/');
      } else {
        ToastHelper.showError(context, 'PIN yang Anda masukkan salah!');
        setState(() {
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Heading
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih Akun Kasir',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masukkan PIN untuk mulai melayani pelanggan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Cashier Selection Cards
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cashiers.length,
                        itemBuilder: (context, index) {
                          final cashier = _cashiers[index];
                          final isSelected =
                              _selectedCashier?['id'] == cashier['id'];

                          return ScaleImpactAnimation(
                            onTap: () {
                              setState(() {
                                _selectedCashier = cashier;
                                _pin = '';
                              });
                            },
                            child: Card(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      cashier['role'] == 'Admin'
                                          ? LucideIcons.userCheck
                                          : LucideIcons.user,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cashier['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(),

                    // PIN Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = _pin.length > index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppColors.primary : Colors.white,
                            border: Border.all(
                              color: isFilled
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // Keyboard PIN
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              '1',
                              '2',
                              '3',
                            ].map((val) => _buildKey(val)).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              '4',
                              '5',
                              '6',
                            ].map((val) => _buildKey(val)).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              '7',
                              '8',
                              '9',
                            ].map((val) => _buildKey(val)).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildUtilityKey(LucideIcons.helpCircle, () {
                                ToastHelper.showInfo(
                                  context,
                                  'PIN Bawaan:\nAdmin: 1234\nStaff: 0000',
                                );
                              }),
                              _buildKey('0'),
                              _buildUtilityKey(
                                LucideIcons.delete,
                                _onPinDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return ScaleImpactAnimation(
      onTap: () => _onPinKeyPress(value),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityKey(IconData icon, VoidCallback action) {
    return ScaleImpactAnimation(
      onTap: action,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.textSecondary),
      ),
    );
  }
}
