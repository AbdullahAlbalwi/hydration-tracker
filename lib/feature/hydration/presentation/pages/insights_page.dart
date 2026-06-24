import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/core/di/injector.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/weekly_insights.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/insights_cubit.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/insights_state.dart';
import 'package:hydration_tracker/feature/hydration/presentation/widgets/weekly_bars.dart';

/// "This week" insights, backed by the getWeeklyInsights callable.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsCubit>(
      create: (_) => getIt<InsightsCubit>(),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('This Week'),
      ),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          return switch (state.status) {
            InsightsStatus.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            InsightsStatus.error => _ErrorView(
              message: state.errorMessage ?? 'Could not load insights.',
              onRetry: () => context.read<InsightsCubit>().load(),
            ),
            InsightsStatus.ready => _InsightsContent(
              insights: state.insights!,
              onRefresh: () => context.read<InsightsCubit>().load(),
            ),
          };
        },
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.insights, required this.onRefresh});

  final WeeklyInsights insights;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _RangeLabel(weekStart: insights.weekStart, weekEnd: insights.weekEnd),
          const SizedBox(height: 16),
          _TrendBanner(trend: insights.trend),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Weekly total',
                  value: _liters(insights.totalMl),
                  icon: Icons.water_drop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Daily average',
                  value: '${insights.dailyAverageMl} ml',
                  icon: Icons.bar_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Goal met',
                  value: '${insights.daysGoalMet} of 7',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Current streak',
                  value:
                      '${insights.currentStreak} '
                      '${insights.currentStreak == 1 ? 'day' : 'days'}',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily intake',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                WeeklyBars(days: insights.days, goalMl: insights.goalMl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _liters(int ml) => '${(ml / 1000).toStringAsFixed(1)} L';
}

class _RangeLabel extends StatelessWidget {
  const _RangeLabel({required this.weekStart, required this.weekEnd});

  final String weekStart;
  final String weekEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$weekStart  →  $weekEnd',
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    );
  }
}

class _TrendBanner extends StatelessWidget {
  const _TrendBanner({required this.trend});

  final WeeklyTrend trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (trend.direction) {
      TrendDirection.up => (
        Icons.trending_up,
        AppColors.success,
        '+${trend.deltaPct}% vs last week',
      ),
      TrendDirection.down => (
        Icons.trending_down,
        AppColors.danger,
        '${trend.deltaPct}% vs last week',
      ),
      TrendDirection.flat => (
        Icons.trending_flat,
        AppColors.textSecondary,
        'No change vs last week',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'avg ${trend.previousWeekAverageMl} ml',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentSoft, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights_outlined,
              color: AppColors.textMuted,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
