import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/glass_card.dart';
import 'promo_code_controller.dart';

class PromoCodeView extends GetView<PromoCodeController> {
  const PromoCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      appBar: AppBar(title: const Text('Promo Code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Promo Code',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apply your assigned promo code to receive a bonus in your wallet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. GIRL-ABC123-DE45',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => GlowButton(
                      label: controller.isApplying.value ? 'Applying...' : 'Apply',
                      onPressed: controller.isApplying.value ? null : controller.applyPromoCode,
                      isLoading: controller.isApplying.value,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final result = controller.lastResult.value;
              if (result == null) return const SizedBox.shrink();

              final isSuccess = result['success'] == true;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.info_outline,
                          color: isSuccess ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSuccess ? 'Promo Applied' : 'Validation Result',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result['message']?.toString() ?? ''),
                    if (result['bonusAmount'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '₹${JsonParse.toDouble(result['bonusAmount']).toStringAsFixed(2)} added to wallet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
