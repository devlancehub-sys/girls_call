import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/glass_card.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Host Login',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login with username & password',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 40),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Enter username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Password', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.login(),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => controller.obscurePassword.toggle(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => GlowButton(
                      label: 'Login',
                      isLoading: controller.isLoading.value,
                      onPressed: controller.login,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Talk more, Earn more',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
