import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/girls_avatar_assets.dart';

class GirlsAvatarPicker extends StatelessWidget {
  const GirlsAvatarPicker({
    super.key,
    required this.selectedFileName,
    required this.onSelected,
  });

  final String? selectedFileName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: GirlsAvatarAssets.presets.length,
      itemBuilder: (context, index) {
        final file = GirlsAvatarAssets.presets[index];
        final selected = file == selectedFileName;

        return GestureDetector(
          onTap: () => onSelected(file),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.glassBorder,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: SvgPicture.asset(
                GirlsAvatarAssets.assetPath(file),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
