import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/user_avatar.dart';
import 'incoming_call_controller.dart';

class IncomingCallView extends StatefulWidget {
  const IncomingCallView({super.key});

  @override
  State<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<IncomingCallView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  IncomingCallController get controller => Get.find<IncomingCallController>();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    if (Get.isRegistered<RingtoneService>()) {
      Get.find<RingtoneService>().startIncomingRingtone();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (Get.isRegistered<RingtoneService>()) {
      Get.find<RingtoneService>().stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScreen(
        body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1 + (_pulseController.value * 0.18);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160 * scale,
                            height: 160 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          Container(
                            width: 130 * scale,
                            height: 130 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: _CallerAvatar(
                      name: controller.callerName,
                      avatarUrl: controller.callerAvatarUrl,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Incoming Call',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      controller.callerName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '₹${controller.ratePerMinute.toStringAsFixed(0)}/min',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      controller.hostEarningPerMinute > 0
                          ? 'You earn ₹${controller.hostEarningPerMinute.toStringAsFixed(0)}/min — boy pays'
                          : 'Boy pays per minute — not you',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: _ActionCircleButton(
                            label: 'Reject',
                            icon: Icons.call_end,
                            color: AppColors.error,
                            loading: controller.isProcessing.value,
                            onTap: controller.rejectCall,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _ActionCircleButton(
                            label: 'Accept',
                            icon: Icons.call,
                            color: AppColors.success,
                            loading: controller.isProcessing.value,
                            onTap: controller.acceptCall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      ),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: UserAvatarImage(
          avatarUrl: avatarUrl,
          name: name,
          size: 114,
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
