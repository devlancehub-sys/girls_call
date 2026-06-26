import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/user_avatar.dart';
import 'call_history_controller.dart';

class CallHistoryView extends GetView<CallHistoryController> {
  const CallHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      appBar: AppBar(title: const Text('Call History')),
      body: Obx(() {
        if (controller.isLoading.value && controller.calls.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.calls.isEmpty) {
          return const Center(
            child: Text('No calls yet', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controller.calls.length,
            itemBuilder: (context, index) {
              final call = controller.calls[index];
              return _CallHistoryTile(call: call);
            },
          ),
        );
      }),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({required this.call});

  final Map<String, dynamic> call;

  @override
  Widget build(BuildContext context) {
    final partnerName = call['partner_name']?.toString() ?? 'User';
    final duration = JsonParse.toInt(call['duration_seconds']);
    final status = call['status']?.toString() ?? 'ended';
    final earning = JsonParse.toDouble(call['host_earning']);
    final createdAt = call['created_at']?.toString();
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: call['partner_avatar']?.toString(),
            name: partnerName,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  status == 'missed' || status == 'rejected'
                      ? statusLabel
                      : _formatDuration(duration),
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          if (status == 'ended' && earning > 0)
            Text(
              '₹${earning.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'missed':
        return 'Missed call';
      case 'rejected':
        return 'Declined';
      case 'ringing':
        return 'Ringing';
      case 'active':
        return 'In progress';
      default:
        return 'Completed';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'missed':
        return AppColors.error;
      case 'rejected':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
