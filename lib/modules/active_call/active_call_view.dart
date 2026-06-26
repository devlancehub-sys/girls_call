import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glow_button.dart';
import 'active_call_controller.dart';

class ActiveCallView extends GetView<ActiveCallController> {
  const ActiveCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return PopScope(
      canPop: false,
      child: AppScreen(
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                controller.callerName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  controller.voiceConnected.value
                      ? controller.formattedDuration
                      : (controller.voiceConnecting.value || controller.voiceAutoRetrying.value)
                          ? 'Connecting voice...'
                          : 'Voice not connected',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: controller.voiceConnected.value
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w300,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () {
                  final err = controller.voiceLastError.value;
                  if (err == null || err.isEmpty || controller.voiceConnected.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      err,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  );
                },
              ),
              Text(
                '${currency.format(controller.ratePerMinute)}/min',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              if (controller.hostEarningPerMinute > 0)
                Text(
                  'You earn ~${currency.format(controller.hostEarningPerMinute)}/min (server rate)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => _CallActionButton(
                      icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      onTap: controller.toggleMute,
                      active: controller.isMuted.value,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Obx(
                    () => _CallActionButton(
                      icon: controller.isSpeakerOn.value
                          ? Icons.volume_up
                          : Icons.volume_off,
                      label: 'Speaker',
                      onTap: controller.toggleSpeaker,
                      active: controller.isSpeakerOn.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(
                () {
                  if (controller.voiceConnected.value ||
                      controller.voiceConnecting.value ||
                      controller.voiceAutoRetrying.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlowButton(
                      label: 'Retry Voice',
                      icon: Icons.refresh,
                      outlined: true,
                      onPressed: controller.retryVoice,
                    ),
                  );
                },
              ),
              Obx(
                () => GlowButton(
                  label: 'End Call',
                  icon: Icons.call_end,
                  isLoading: controller.isEnding.value,
                  onPressed: controller.endCall,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.card,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.glassBorder,
              ),
            ),
            child: Icon(icon, color: active ? AppColors.primary : Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
