import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/host_availability_service.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glow_button.dart';
import '../../routes/app_routes.dart';
import 'dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return AppScreen(
      embeddedInShell: !showAppBar,
      appBar: showAppBar ? AppBar(title: const Text('Dashboard')) : null,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${controller.hostName.value}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Obx(() {
                                final status = controller.hostStatus;
                                final label = switch (status) {
                                  HostStatus.available => 'Available — receiving calls',
                                  HostStatus.busy => 'Busy — not receiving calls',
                                  HostStatus.offline => 'Offline',
                                };
                                final color = switch (status) {
                                  HostStatus.available => AppColors.success,
                                  HostStatus.busy => AppColors.warning,
                                  HostStatus.offline => AppColors.textSecondary,
                                };
                                return Text(
                                  label,
                                  style: TextStyle(color: color),
                                );
                              }),
                            ],
                          ),
                        ),
                        Obx(
                          () => controller.isTogglingAvailability.value
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Switch.adaptive(
                                  value: controller.isAvailable,
                                  activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                                  activeThumbColor: AppColors.success,
                                  onChanged: controller.toggleAvailability,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Online today: ${controller.formatDuration(controller.onlineDurationSeconds.value)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DailyTaskCard(controller: controller, currency: currency),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Calls Today',
                      value: '${controller.callsToday.value}',
                      icon: Icons.call,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Earnings Today',
                      value: currency.format(controller.todayEarnings.value),
                      icon: Icons.today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Wallet',
                      value: currency.format(controller.walletBalance.value),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Earnings',
                      value: currency.format(controller.totalEarnings.value),
                      icon: Icons.savings_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Calls',
                      value: '${controller.totalCalls.value}',
                      icon: Icons.history,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Rating',
                      value: controller.rating.value.toStringAsFixed(1),
                      icon: Icons.star,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate per minute',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          currency.format(controller.ratePerMinute.value),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'You earn 60% per billed minute',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Withdrawable',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          currency.format(controller.withdrawBalance.value),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _MenuTile(
                icon: Icons.local_offer_outlined,
                title: 'Promo Code',
                subtitle: 'Redeem your assigned bonus code',
                onTap: () => Get.toNamed(AppRoutes.promoCode),
              ),
              _MenuTile(
                icon: Icons.history,
                title: 'Call History',
                subtitle: 'Missed, completed and declined calls',
                onTap: () => Get.toNamed(AppRoutes.callHistory),
              ),
              _MenuTile(
                icon: Icons.payments_outlined,
                title: 'Earnings History',
                subtitle: 'View all your earnings',
                onTap: () => Get.toNamed(AppRoutes.earnings),
              ),
              _MenuTile(
                icon: Icons.account_balance_outlined,
                title: 'Withdraw',
                subtitle: 'Withdraw your earnings',
                onTap: () => Get.toNamed(AppRoutes.withdraw),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DailyTaskCard extends StatelessWidget {
  const _DailyTaskCard({required this.controller, required this.currency});

  final DashboardController controller;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Daily Task',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.earningStatusActive.value
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.earningStatusActive.value ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: controller.earningStatusActive.value
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete ${controller.dailyMinCalls.value} calls OR ${controller.dailyMinMinutes.value} minutes to unlock withdrawals & reward',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${controller.streakCount.value} day streak',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressRow(
              label: 'Calls',
              value: '${controller.completedCalls.value}/${controller.dailyMinCalls.value}',
              percent: controller.progressCallsPercent.value,
            ),
            const SizedBox(height: 12),
            _ProgressRow(
              label: 'Minutes',
              value: '${controller.completedMinutes.value}/${controller.dailyMinMinutes.value}',
              percent: controller.progressMinutesPercent.value,
            ),
            const SizedBox(height: 16),
            if (controller.targetMet.value && controller.rewardClaimed.value)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Task complete! Reward ${currency.format(controller.dailyRewardAmount.value)} claimed',
                      style: TextStyle(color: AppColors.success),
                    ),
                  ),
                ],
              )
            else if (controller.canClaimReward.value)
              GlowButton(
                label: 'Claim ${currency.format(controller.dailyRewardAmount.value)} Reward',
                isLoading: controller.isClaimingReward.value,
                onPressed: controller.claimDailyReward,
              )
            else if (controller.targetMet.value)
              Text(
                'Task complete — reward processing…',
                style: TextStyle(color: AppColors.success),
              )
            else
              Text(
                'Daily reward: ${currency.format(controller.dailyRewardAmount.value)} on completion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Weekly Bonus',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete daily task all ${controller.weeklyDaysRequired.value} days (Mon–Sun). Weekly bonus credited after the week ends — only if every day is done.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: controller.weeklyDayStatus.isEmpty
                  ? List.generate(controller.weeklyDaysRequired.value, (index) {
                      final done = index < controller.weeklyDaysCompleted.value;
                      return _WeekDayDot(done: done, label: '');
                    })
                  : controller.weeklyDayStatus.map((day) {
                      final done = day['completed'] == true;
                      final label = day['day_label']?.toString() ?? '';
                      return _WeekDayDot(done: done, label: label);
                    }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.weeklyDaysCompleted.value}/${controller.weeklyDaysRequired.value} days completed this week',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (controller.weeklyBonusGranted.value)
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weekly bonus ${currency.format(controller.weeklyBonusAmount.value)} received!',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            else if (controller.canClaimWeeklyBonus.value)
              GlowButton(
                label: 'Claim Last Week ${currency.format(controller.weeklyBonusAmount.value)}',
                isLoading: controller.isClaimingWeeklyBonus.value,
                onPressed: controller.claimWeeklyBonus,
              )
            else if (controller.previousWeekBonusPending.value)
              Text(
                'Last week complete — claim your weekly bonus',
                style: TextStyle(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.textSecondary.withValues(alpha: 0.15),
            border: Border.all(
              color: done ? AppColors.success : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Icon(
              done ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: done ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.percent,
  });

  final String label;
  final String value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: AppColors.textSecondary.withValues(alpha: 0.2),
            color: percent >= 100 ? AppColors.success : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
