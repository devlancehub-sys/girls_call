import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/letter_avatar.dart';
import 'online_users_controller.dart';

class OnlineUsersView extends GetView<OnlineUsersController> {
  const OnlineUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.onlineUsers.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.onlineUsers.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadUsers,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'No users online',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadUsers,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.onlineUsers.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = controller.onlineUsers[index];
            final rawName = user.name?.trim().isNotEmpty == true ? user.name! : 'User';
            final displayName = truncateWords(rawName, 5);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LetterAvatar(name: rawName, radius: 26),
                      if (user.isBusy)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning,
                              border: Border.all(color: AppColors.card, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.isBusy)
                          Text(
                            'Busy',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => _CallButton(
                      isLoading: controller.isCalling.value,
                      enabled: !controller.isCalling.value,
                      busy: user.isBusy,
                      onPressed: () => controller.callUser(user),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
    this.busy = false,
  });

  final bool isLoading;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: busy ? AppColors.warning.withValues(alpha: 0.2) : AppColors.primary,
          foregroundColor: busy ? AppColors.warning : Colors.white,
          disabledBackgroundColor: AppColors.card,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: busy ? AppColors.warning : Colors.white,
                ),
              )
            : Icon(busy ? Icons.phone_disabled : Icons.call, size: 16),
        label: Text(
          busy ? 'Busy' : 'Call',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
