import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glow_button.dart';
import 'outgoing_call_controller.dart';

class OutgoingCallView extends GetView<OutgoingCallController> {
  const OutgoingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Calling ${controller.partnerName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Boy\'s wallet will be charged — you never pay',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'You earn 60% of the per-minute rate',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 48),
              GlowButton(
                label: 'Cancel',
                outlined: true,
                onPressed: () => controller.cancel(),
              ),
            ],
          ),
        ),
    );
  }
}
