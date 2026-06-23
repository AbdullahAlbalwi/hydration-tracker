import 'package:flutter/material.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';

/// A 7-bar visual of the week built from plain Containers (no chart library).
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({required this.days, required this.goalMl, super.key});

  final List<DayBar> days;
  final int goalMl;

  static const _maxBarHeight = 130.0;
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxBarHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map(_buildBar).toList(),
      ),
    );
  }

  Widget _buildBar(DayBar day) {
    final ratio = goalMl <= 0 ? 0.0 : (day.totalMl / goalMl).clamp(0.0, 1.0);
    final height = (ratio * _maxBarHeight).clamp(4.0, _maxBarHeight);
    final weekday = _weekdayOf(day.dateKey);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            day.totalMl >= 1000
                ? '${(day.totalMl / 1000).toStringAsFixed(1)}L'
                : '${day.totalMl}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: day.goalMet
                    ? const [AppColors.primary, AppColors.accent]
                    : [AppColors.surface, AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weekday,
            style: TextStyle(
              color: day.goalMet ? AppColors.accentSoft : AppColors.textMuted,
              fontSize: 12,
              fontWeight: day.goalMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayOf(String dateKey) {
    final parts = dateKey.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return '?';
    final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
    return _weekdayLetters[date.weekday - 1];
  }
}
