import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/glass_card.dart';
import 'withdraw_controller.dart';

class WithdrawView extends GetView<WithdrawController> {
  const WithdrawView({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return AppScreen(
      appBar: AppBar(title: const Text('Withdraw')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return _WithdrawForm(controller: controller, currency: currency);
      }),
    );
  }
}

class _WithdrawForm extends StatelessWidget {
  const _WithdrawForm({required this.controller, required this.currency});

  final WithdrawController controller;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Obx(
            () => GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(controller.withdrawBalance.value),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Amount', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: controller.amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Minimum ₹100',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 20),
          Text('Method', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: controller.methods.map((method) {
              return Obx(
                () => ChoiceChip(
                  label: Text(method.toUpperCase()),
                  selected: controller.selectedMethod.value == method,
                  onSelected: (_) => controller.selectedMethod.value = method,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Account Details', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: controller.accountController,
              decoration: InputDecoration(
                hintText: controller.selectedMethod.value == 'upi'
                    ? 'UPI ID'
                    : 'Account number / Paytm number',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => GlowButton(
              label: 'Request Withdraw',
              isLoading: controller.isSubmitting.value,
              onPressed: controller.submitWithdraw,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Withdraw History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              if (controller.history.isEmpty) {
                return GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No withdraw requests yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: controller.history.map((item) {
                  final amount = JsonParse.toDouble(item['amount']);
                  final status = item['status']?.toString() ?? 'pending';
                  final method = item['method']?.toString() ?? '';

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.format(amount),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                method.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.success;
      case 'rejected':
        color = AppColors.error;
      case 'processing':
        color = AppColors.warning;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
