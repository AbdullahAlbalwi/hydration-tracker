import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/core/date_key.dart';
import 'package:hydration_tracker/core/di/injector.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';
import 'package:hydration_tracker/feature/assistant/presentation/chat_sheet.dart';
import 'package:hydration_tracker/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/home_cubit.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/home_state.dart';
import 'package:hydration_tracker/feature/hydration/presentation/pages/insights_page.dart';
import 'package:hydration_tracker/feature/hydration/presentation/widgets/day_selector.dart';
import 'package:hydration_tracker/feature/hydration/presentation/widgets/quick_add_bar.dart';
import 'package:hydration_tracker/feature/hydration/presentation/widgets/water_log_tile.dart';
import 'package:hydration_tracker/feature/hydration/presentation/widgets/water_ring.dart';

/// Per-day hydration Home screen: day selector, progress ring, quick-add and
/// the day's logs. The ring reads the server summary; the client never sums.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => getIt<HomeCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: BlocSelector<HomeCubit, HomeState, DateTime>(
        selector: (state) => state.selectedDate,
        builder: (context, selectedDate) {
          return FloatingActionButton.extended(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Ask'),
            onPressed: () => showChatSheet(context, dateKeyOf(selectedDate)),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Hydration Tracker',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'This week',
            icon: const Icon(Icons.insights_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: BlocConsumer<HomeCubit, HomeState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null &&
            curr.errorMessage != prev.errorMessage &&
            curr.status != HomeStatus.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something failed.'),
              ),
            );
        },
        builder: (context, state) {
          final cubit = context.read<HomeCubit>();
          return Column(
            children: [
              const SizedBox(height: 8),
              _DateHeader(date: state.selectedDate),
              DaySelector(
                selectedDate: state.selectedDate,
                onSelect: cubit.selectDate,
              ),
              const SizedBox(height: 8),
              Expanded(child: _Content(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? 'Today'
        : '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      HomeStatus.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      HomeStatus.error => _ErrorView(
        message: state.errorMessage ?? 'Could not load this day.',
        onRetry: () => context.read<HomeCubit>().selectDate(state.selectedDate),
      ),
      HomeStatus.ready => _DayContent(
        summary: state.summary ?? DailySummary.empty('today'),
        logs: state.logs,
      ),
    };
  }
}

class _DayContent extends StatelessWidget {
  const _DayContent({required this.summary, required this.logs});

  final DailySummary summary;
  final List<WaterLog> logs;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(child: WaterRing(summary: summary)),
        const SizedBox(height: 28),
        QuickAddBar(onAdd: cubit.addWater),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's log",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${logs.length} ${logs.length == 1 ? 'entry' : 'entries'}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          const _EmptyLogs()
        else
          ...logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WaterLogTile(
                log: log,
                onDelete: () => _deleteWithUndo(context, cubit, log),
              ),
            ),
          ),
      ],
    );
  }

  void _deleteWithUndo(BuildContext context, HomeCubit cubit, WaterLog log) {
    cubit.deleteLog(log.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${log.amountMl} ml'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.addWater(log.amountMl),
          ),
        ),
      );
  }
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.water_drop_outlined, color: AppColors.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No water logged yet.\nTap a quick-add button to start.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
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
            const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 44),
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
