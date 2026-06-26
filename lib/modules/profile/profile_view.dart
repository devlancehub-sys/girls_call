import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/girls_avatar_picker.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/user_avatar.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      embeddedInShell: !showAppBar,
      appBar: showAppBar ? AppBar(title: const Text('Profile')) : null,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return _ProfileForm(controller: controller);
      }),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Row(
              children: [
                Obx(
                  () => UserAvatar(
                    avatarUrl: controller.avatarUrl.value,
                    name: controller.name.value.isNotEmpty
                        ? controller.name.value
                        : controller.username.value,
                    radius: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          controller.name.value.isNotEmpty
                              ? controller.name.value
                              : controller.username.value,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          '@${controller.username.value}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Obx(
                        () => Text(
                          '${controller.totalCalls.value}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Text(
                        'Total Calls',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Obx(
                        () => Text(
                          controller.rating.value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Obx(
              () => SwitchListTile(
                title: const Text('Vibrate on incoming call'),
                subtitle: const Text(
                  'Phone vibrates when you receive a call',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                secondary: const Icon(
                  Icons.vibration_rounded,
                  color: AppColors.primary,
                ),
                value: controller.callVibrateEnabled.value,
                activeThumbColor: AppColors.primary,
                onChanged: controller.setCallVibrateEnabled,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose Avatar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shown to callers in the boys app — saved as preset, not uploaded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => GirlsAvatarPicker(
              selectedFileName: controller.selectedAvatarFileName,
              onSelected: controller.selectAvatar,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller.nameController,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.ageController,
            keyboardType: TextInputType.number,
            maxLength: 3,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.aboutController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'About',
              prefixIcon: Icon(Icons.info_outline),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => GlowButton(
              label: 'Save Profile',
              isLoading: controller.isSaving.value,
              onPressed: controller.saveProfile,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => GlowButton(
              label: 'Logout',
              outlined: true,
              isLoading: controller.isLoggingOut.value,
              onPressed: controller.logout,
            ),
          ),
        ],
      ),
    );
  }
}
