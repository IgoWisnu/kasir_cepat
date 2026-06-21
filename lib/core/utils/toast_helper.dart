import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../themes/app_colors.dart';

class ToastHelper {
  ToastHelper._();

  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: LucideIcons.checkCircle2,
    );
  }

  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: LucideIcons.alertTriangle,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: LucideIcons.info,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: LucideIcons.alertCircle,
    );
  }

  static void _showToast(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
