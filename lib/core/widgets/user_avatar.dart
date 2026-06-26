import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/girls_avatar_assets.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 28,
  });

  final String? avatarUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final preset = GirlsAvatarAssets.presetFileName(avatarUrl);
    if (preset != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        child: ClipOval(
          child: SvgPicture.asset(
            GirlsAvatarAssets.assetPath(preset),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final url = avatarUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return _LetterFallback(name: name, radius: radius);
  }
}

class UserAvatarImage extends StatelessWidget {
  const UserAvatarImage({
    super.key,
    this.avatarUrl,
    this.name,
    this.size = 120,
  });

  final String? avatarUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preset = GirlsAvatarAssets.presetFileName(avatarUrl);
    if (preset != null) {
      return ClipOval(
        child: SvgPicture.asset(
          GirlsAvatarAssets.assetPath(preset),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final url = avatarUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _LetterFallback(name: name, radius: size / 2),
        ),
      );
    }

    return _LetterFallback(name: name, radius: size / 2);
  }
}

class _LetterFallback extends StatelessWidget {
  const _LetterFallback({this.name, required this.radius});

  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.trim().isNotEmpty ?? false) ? name!.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
