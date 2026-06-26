import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glass_card.dart';
import 'earnings_controller.dart';

class EarningsView extends GetView<EarningsController> {
  const EarningsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      appBar: AppBar(title: const Text('Earnings')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Today',
                      value: controller.currency.format(controller.todayEarnings.value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'This Week',
                      value: controller.currency.format(controller.weeklyEarnings.value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'This Month',
                      value: controller.currency.format(controller.monthlyEarnings.value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total',
                      value: controller.currency.format(controller.totalEarnings.value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (controller.history.isEmpty)
                GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No earnings yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                )
              else
                ...controller.history.map((item) {
                  final amount = JsonParse.toDouble(item['amount']);
                  final createdAt = JsonParse.toDateTime(item['created_at']);
                  final description = item['description']?.toString() ?? 'Call earning';
                  final callerName = item['caller_name']?.toString();

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: AppColors.success),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                callerName ?? description,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (createdAt != null)
                                Text(
                                  controller.dateFormat.format(createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '+${controller.currency.format(amount)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
