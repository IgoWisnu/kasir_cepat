import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../core/utils/impact_animation.dart';
import '../../user/domain/entities/user.dart';
import '../domain/usecases/skip_first_time_pin.dart';
import '../domain/usecases/update_first_time_pin.dart';
import 'provider/auth_provider.dart';

class FirstTimeLoginPage extends ConsumerStatefulWidget {
  const FirstTimeLoginPage({super.key});

  @override
  ConsumerState<FirstTimeLoginPage> createState() => _FirstTimeLoginPageState();
}

class _FirstTimeLoginPageState extends ConsumerState<FirstTimeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  int _currentPage = 0;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _savePin(User user) async {
    if (!_formKey.currentState!.validate()) return;

    final newPin = _newPinController.text.trim();

    setState(() {
      _isSaving = true;
    });

    final usecase = ref.read(updateFirstTimePinUseCaseProvider);
    final result = await usecase(
      UpdateFirstTimePinParams(user: user, newPin: newPin),
    );

    if (mounted) {
      result.fold(
        (failure) {
          ToastHelper.showError(context, failure.message);
          setState(() {
            _isSaving = false;
          });
        },
        (_) {
          final updatedUser = user.copyWith(pin: newPin, isFirstLogin: false);
          ref.read(activeUserProvider.notifier).setUser(updatedUser);
          ToastHelper.showSuccess(context, 'PIN berhasil diperbarui!');
          context.go('/');
        },
      );
    }
  }

  Future<void> _skipPinChange(User user) async {
    setState(() {
      _isSaving = true;
    });

    final usecase = ref.read(skipFirstTimePinUseCaseProvider);
    final result = await usecase(SkipFirstTimePinParams(user: user));

    if (mounted) {
      result.fold(
        (failure) {
          ToastHelper.showError(context, failure.message);
          setState(() {
            _isSaving = false;
          });
        },
        (_) {
          final updatedUser = user.copyWith(isFirstLogin: false);
          ref.read(activeUserProvider.notifier).setUser(updatedUser);
          ToastHelper.showInfo(context, 'Masuk menggunakan PIN bawaan.');
          context.go('/');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(activeUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Langkah ${_currentPage + 1} dari 2',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Progress Dots
                  Row(
                    children: List.generate(2, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey[350],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Page View containing Onboarding slides
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Force button usage
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // SLIDE 1: Welcome & Usage Walkthrough
                  _buildWelcomeSlide(user),

                  // SLIDE 2: PIN Configuration Form
                  _buildPinFormSlide(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Large Welcome Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Welcome Header
          Text(
            'Selamat Datang, ${user.name}!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Akun kasir Anda sudah aktif. Mari pelajari cara masuk ke aplikasi dengan mudah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Card: Steps to Login
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      LucideIcons.helpCircle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Panduan Cara Masuk (Login)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTutorialStep(
                  '1',
                  'Pilih Nama Kasir',
                  'Ketuk nama atau kartu kasir Anda pada daftar di halaman utama login.',
                ),
                const SizedBox(height: 16),
                _buildTutorialStep(
                  '2',
                  'Masukkan PIN Rahasia',
                  'Ketikkan 4 digit angka PIN pengaman Anda menggunakan tombol angka.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Card: Current Temporary PIN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.keyRound,
                      size: 18,
                      color: Colors.amber[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PIN Bawaan Anda Saat Ini:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _obscureCurrentPin ? '••••' : user.pin,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: Colors.amber[900],
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _obscureCurrentPin
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 20,
                        color: Colors.amber[800],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPin = !_obscureCurrentPin;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Next Button
          ScaleImpactAnimation(
            onTap: _nextPage,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjutkan ke Atur PIN Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinFormSlide(User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Header Shield Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  size: 56,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            const Text(
              'Atur PIN Pengaman Baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ganti PIN bawaan dengan PIN pilihan Anda sendiri untuk menjamin keamanan akses transaksi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Form inputs container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // New PIN
                  TextFormField(
                    controller: _newPinController,
                    obscureText: _obscureNewPin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'PIN Baru (4 Digit)',
                      counterText: '',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPin ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPin = !_obscureNewPin;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'PIN baru wajib diisi';
                      }
                      if (val.trim().length != 4) {
                        return 'PIN harus terdiri dari 4 digit angka';
                      }
                      if (val.trim() == user.pin) {
                        return 'PIN baru harus berbeda dengan PIN bawaan';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm PIN
                  TextFormField(
                    controller: _confirmPinController,
                    obscureText: _obscureConfirmPin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi PIN Baru',
                      counterText: '',
                      prefixIcon: const Icon(LucideIcons.checkSquare, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPin
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPin = !_obscureConfirmPin;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Konfirmasi PIN wajib diisi';
                      }
                      if (val.trim() != _newPinController.text.trim()) {
                        return 'PIN konfirmasi tidak cocok';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions Section
            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Save PIN & Enter
                      ScaleImpactAnimation(
                        onTap: () => _savePin(user),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Simpan PIN & Mulai Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Skip action
                      TextButton(
                        onPressed: () => _skipPinChange(user),
                        child: const Text(
                          'Lewati & Gunakan PIN Bawaan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Back Button
                      TextButton.icon(
                        onPressed: _prevPage,
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        label: const Text(
                          'Kembali ke Langkah 1',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
