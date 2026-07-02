import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../core/utils/impact_animation.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../domain/entities/user.dart';
import 'provider/user_provider.dart';

class UserFormPage extends ConsumerStatefulWidget {
  final User? editingUser;

  const UserFormPage({super.key, this.editingUser});

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _pinController;
  
  UserRole _selectedRole = UserRole.staff;
  bool _isActive = true;
  bool _obscurePin = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editingUser?.name ?? '');
    _usernameController = TextEditingController(text: widget.editingUser?.username ?? '');
    _pinController = TextEditingController(text: widget.editingUser?.pin ?? '');
    
    if (widget.editingUser != null) {
      _selectedRole = widget.editingUser!.role;
      _isActive = widget.editingUser!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onSave(User currentUser, bool hasAnotherOwner) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // 1. Prevent self-demotion or self-deactivation
    final isSelf = widget.editingUser?.id == currentUser.id;
    final roleToSave = isSelf ? widget.editingUser!.role : _selectedRole;
    final statusToSave = isSelf ? widget.editingUser!.isActive : _isActive;

    // 2. Prevent Owner role creation if another owner exists
    if (roleToSave == UserRole.owner && hasAnotherOwner) {
      ToastHelper.showError(context, 'Gagal menyimpan: Hanya boleh ada satu Owner di sistem.');
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final userToSave = User(
      id: widget.editingUser?.id,
      name: _nameController.text.trim(),
      username: _usernameController.text.trim().toLowerCase(),
      pin: _pinController.text.trim(),
      role: roleToSave,
      isActive: statusToSave,
      createdAt: widget.editingUser?.createdAt ?? DateTime.now(),
    );

    final errorMsg = await ref.read(userListProvider.notifier).saveUserProfile(
          userToSave: userToSave,
          currentUser: currentUser,
        );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (errorMsg != null) {
        ToastHelper.showError(context, errorMsg);
      } else {
        ToastHelper.showSuccess(
          context,
          widget.editingUser != null
              ? 'Data kasir berhasil diperbarui!'
              : 'Kasir baru berhasil didaftarkan!',
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);

    // Guard Clause: Only Owner can manage users
    if (activeUser == null || !activeUser.role.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Text('Hanya Owner yang memiliki izin untuk mengakses halaman ini.'),
        ),
      );
    }

    final isEditing = widget.editingUser != null;
    final isSelf = widget.editingUser?.id == activeUser.id;

    // Check single owner constraint reactively from cache list
    final usersList = ref.watch(userListProvider).value ?? [];
    final hasAnotherOwner = usersList.any(
      (u) => u.role.isOwner && u.id != widget.editingUser?.id,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Akun Kasir' : 'Daftar Kasir Baru'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning note if editing own profile
                if (isSelf) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, color: Colors.blue[800], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Anda sedang mengedit profil Anda sendiri. Perubahan peran atau status dinonaktifkan untuk mencegah lockout.',
                            style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Full Name field
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama lengkap kasir',
                    prefixIcon: Icon(LucideIcons.user, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Username field
                const Text(
                  'Username',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Username unik (tanpa spasi)',
                    prefixIcon: Icon(LucideIcons.atSign, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (value.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    // Validate username uniqueness in client cache
                    final exists = usersList.any(
                      (u) => u.username == value.trim().toLowerCase() && u.id != widget.editingUser?.id,
                    );
                    if (exists) {
                      return 'Username sudah digunakan oleh kasir lain';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // PIN field
                const Text(
                  'PIN Akses (4 Digit)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: 'PIN login kasir (4 angka)',
                    prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
                    counterText: '',
                    suffixIcon: ScaleImpactAnimation(
                      onTap: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                      child: Icon(
                        _obscurePin ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'PIN wajib diisi';
                    }
                    if (value.trim().length != 4) {
                      return 'PIN harus tepat 4 digit angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Role Dropdown
                const Text(
                  'Peran (Role)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.shieldCheck, size: 20),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: UserRole.staff,
                      child: const Text('Staff (Kasir biasa)'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.owner,
                      // Disable dropdown item if single owner restriction applies
                      enabled: !hasAnotherOwner,
                      child: Text(
                        hasAnotherOwner ? 'Owner (Hanya boleh satu Owner)' : 'Owner (Store Owner)',
                        style: TextStyle(
                          color: hasAnotherOwner ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  // Disable selection completely if editing self
                  onChanged: isSelf
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                ),
                if (hasAnotherOwner && _selectedRole != UserRole.owner) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Peran "Owner" tidak dapat dipilih karena sudah ada Owner lain terdaftar di sistem.',
                    style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                  ),
                ],
                const SizedBox(height: 20),

                // Status Switch
                if (!isSelf) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Kasir Aktif',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kasir yang tidak aktif tidak akan bisa masuk login',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isActive = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Submit Button
                ScaleImpactAnimation(
                  onTap: () {
                    if (!_isSubmitting) {
                      _onSave(activeUser, hasAnotherOwner);
                    }
                  },
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEditing ? 'Simpan Perubahan' : 'Daftarkan Kasir',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
