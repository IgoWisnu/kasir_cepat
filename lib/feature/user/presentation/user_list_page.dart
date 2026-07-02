import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../core/utils/impact_animation.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../domain/entities/user.dart';
import 'provider/user_provider.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(User user, User currentUser) async {
    // 1. Prevent self-deactivation
    if (user.id == currentUser.id) {
      ToastHelper.showError(context, 'Akses ditolak: Anda tidak dapat menonaktifkan akun Anda sendiri.');
      return;
    }

    final updatedUser = user.copyWith(isActive: !user.isActive);
    final errorMsg = await ref.read(userListProvider.notifier).saveUserProfile(
          userToSave: updatedUser,
          currentUser: currentUser,
        );

    if (mounted) {
      if (errorMsg != null) {
        ToastHelper.showError(context, errorMsg);
      } else {
        ToastHelper.showSuccess(
          context,
          'User "${user.name}" berhasil ${updatedUser.isActive ? 'diaktifkan' : 'dinonaktifkan'}!',
        );
      }
    }
  }

  Future<void> _deleteUser(User user, User currentUser) async {
    // 1. Prevent self-deletion
    if (user.id == currentUser.id) {
      ToastHelper.showError(context, 'Akses ditolak: Anda tidak dapat menghapus akun Anda sendiri.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kasir'),
        content: Text('Apakah Anda yakin ingin menghapus kasir "${user.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (user.id == null) return;
      final errorMsg = await ref.read(userListProvider.notifier).deleteUserProfile(
            idToDelete: user.id!,
            currentUser: currentUser,
          );

      if (mounted) {
        if (errorMsg != null) {
          ToastHelper.showError(context, errorMsg);
        } else {
          ToastHelper.showSuccess(context, 'Kasir "${user.name}" berhasil dihapus!');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);

    // Enforce Access Control
    if (activeUser == null || !activeUser.role.isOwner) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kelola Pengguna'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldAlert, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Akses Ditolak',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hanya Owner yang memiliki izin untuk mengelola akun kasir/pengguna.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final userListState = ref.watch(userListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        leading: ScaleImpactAnimation(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          ),
        ),
      ),
      floatingActionButton: ScaleImpactAnimation(
        onTap: () => context.push('/settings/users/form'),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: null, // Handled by ScaleImpactAnimation wrapper
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kasir...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? ScaleImpactAnimation(
                        onTap: () => _searchController.clear(),
                        child: const Icon(LucideIcons.x, size: 18),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Users list
          Expanded(
            child: userListState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Gagal memuat kasir: $err', textAlign: TextAlign.center),
                ),
              ),
              data: (users) {
                // Filter users based on search query
                final filteredUsers = users.where((user) {
                  return user.name.toLowerCase().contains(_searchQuery) ||
                      user.username.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? 'Kasir tidak ditemukan' : 'Belum ada data kasir',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isSelf = user.id == activeUser.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () => context.push('/settings/users/form', extra: user),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: isSelf
                                    ? AppColors.primaryLight
                                    : Colors.grey[100],
                                child: Icon(
                                  user.role.isOwner ? LucideIcons.userCheck : LucideIcons.user,
                                  color: isSelf
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Role Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.role.isOwner
                                          ? Colors.red[50]
                                          : Colors.teal[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.role.isOwner ? 'Owner' : 'Staff',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: user.role.isOwner
                                            ? Colors.red[700]
                                            : Colors.teal[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '@${user.username}${isSelf ? ' (Anda)' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Switch to Toggle Status
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: user.isActive,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: isSelf
                                          ? null // Disable self deactivation
                                          : (_) => _toggleUserStatus(user, activeUser),
                                    ),
                                  ),
                                  // Delete Button
                                  if (!isSelf)
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.grey),
                                      onPressed: () => _deleteUser(user, activeUser),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
