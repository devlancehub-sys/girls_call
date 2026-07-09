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
              _TierCard(controller: controller),
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
                        Obx(
                          () => Text(
                            'Day: ${controller.dayHostShare.value.toInt()}% | Night: ${controller.nightHostShare.value.toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                ),
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

class _TierCard extends StatelessWidget {
  const _TierCard({required this.controller});

  final DashboardController controller;

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
                    'Creator Tier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTierColor(controller.currentTier.value).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.currentTierLabel.value.isNotEmpty 
                        ? controller.currentTierLabel.value.toUpperCase() 
                        : controller.currentTier.value.toUpperCase(),
                    style: TextStyle(
                      color: _getTierColor(controller.currentTier.value),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Lifetime: ${controller.lifetimeTalkMinutes.value} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.nextTierLabel.value.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.arrow_upward, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${controller.minutesToNextTier.value} min to ${controller.nextTierLabel.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Obx(
              () {
                final isOffline = controller.isOffline;
                if (!isOffline) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tier can only be changed while you are offline',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['iron', 'silver', 'gold', 'diamond'].map((tier) {
                    final isUnlocked = controller.unlockedTiers.contains(tier);
                    final isCurrent = controller.currentTier.value == tier;
                    final requiredMinutes = controller.tierRequirements[tier.toLowerCase()] ?? 0;
                    final hasEnoughMinutes = controller.lifetimeTalkMinutes.value >= requiredMinutes;
                    final canSelect = isUnlocked && !isCurrent && hasEnoughMinutes;
                    
                    return InkWell(
                      onTap: canSelect
                          ? () => controller.changeTier(tier)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _getTierColor(tier)
                              : canSelect
                                  ? _getTierColor(tier).withValues(alpha: 0.15)
                                  : AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? _getTierColor(tier)
                                : canSelect
                                    ? _getTierColor(tier).withValues(alpha: 0.4)
                                    : AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasEnoughMinutes ? Icons.check : Icons.lock,
                              size: 14,
                              color: isCurrent
                                  ? Colors.white
                                  : hasEnoughMinutes
                                      ? _getTierColor(tier)
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tier.toUpperCase(),
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : hasEnoughMinutes
                                        ? _getTierColor(tier)
                                        : AppColors.textSecondary,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'iron':
        return const Color(0xFF6B7280);
      case 'silver':
        return const Color(0xFF9CA3AF);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'diamond':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
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
