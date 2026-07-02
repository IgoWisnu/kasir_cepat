import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/themes/app_colors.dart';

class ProductThumbnail extends StatelessWidget {
  final String? imagePath;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;

  const ProductThumbnail({
    super.key,
    this.imagePath,
    this.size = 56,
    this.iconSize = 24,
    this.color,
    this.iconColor,
  });

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'shoppingBag':
        return LucideIcons.shoppingBag;
      case 'coffee':
        return LucideIcons.coffee;
      case 'sandwich':
        return LucideIcons.sandwich;
      case 'glassWater':
        return LucideIcons.glassWater;
      case 'cake':
        return LucideIcons.cake;
      case 'iceCream':
        return LucideIcons.iceCream;
      case 'apple':
        return LucideIcons.apple;
      case 'cookie':
        return LucideIcons.cookie;
      case 'soup':
        return LucideIcons.soup;
      case 'pizza':
        return LucideIcons.pizza;
      case 'gift':
        return LucideIcons.gift;
      case 'shirt':
        return LucideIcons.shirt;
      default:
        return LucideIcons.package;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImagePath = imagePath != null && imagePath!.isNotEmpty;
    final isLocalFile = hasImagePath &&
        (imagePath!.startsWith('/') ||
            imagePath!.contains('\\') ||
            imagePath!.contains(':'));

    Widget child;

    if (isLocalFile) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        child = Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else {
        child = Icon(
          LucideIcons.package,
          size: iconSize,
          color: iconColor ?? AppColors.textLight,
        );
      }
    } else if (hasImagePath) {
      child = Icon(
        _getIconData(imagePath),
        size: iconSize,
        color: iconColor ?? AppColors.primary,
      );
    } else {
      child = Icon(
        LucideIcons.package,
        size: iconSize,
        color: iconColor ?? AppColors.primary,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}
