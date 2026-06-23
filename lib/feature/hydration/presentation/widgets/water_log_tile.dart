import 'package:flutter/material.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';

/// A single log row. Swipe to delete; the page offers an Undo afterwards.
class WaterLogTile extends StatelessWidget {
  const WaterLogTile({required this.log, required this.onDelete, super.key});

  final WaterLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.water_drop, color: Colors.white, size: 20),
          ),
          title: Text(
            '${log.amountMl} ml',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _timeLabel(log.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime? at) {
    if (at == null) return 'Just now';
    final local = at.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
