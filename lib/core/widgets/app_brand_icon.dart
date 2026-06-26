import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

/// App logo on a pink gradient circle.
class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({
    super.key,
    required this.size,
    this.iconScale = 0.78,
  });

  final double size;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * iconScale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: size * 0.18,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: Image.asset(
          AppAssets.appIcon,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
