import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/core/date_key.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/water_log.dart';
import 'package:hydration_tracker/feature/hydration/domain/hydration_exception.dart';
import 'package:hydration_tracker/feature/hydration/domain/repositories/hydration_repository.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/home_state.dart';

/// Drives the Home screen for one selected day.
///
/// It holds `selectedDate` in state and re-subscribes whenever the day changes
/// — each day reads its own `daily_summaries/{dateKey}` document and that day's
/// `water_logs`. The ring/totals come from the server summary; the client never
/// sums the logs itself.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(HomeState(selectedDate: _todayDate())) {
    selectDate(state.selectedDate);
  }

  final HydrationRepository _repository;

  StreamSubscription<DailySummary>? _summarySub;
  StreamSubscription<List<WaterLog>>? _logsSub;

  static DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Switches the active day and reloads everything below the selector.
  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    _summarySub?.cancel();
    _logsSub?.cancel();

    emit(
      state.copyWith(
        selectedDate: normalized,
        status: HomeStatus.loading,
        summary: null,
        logs: const [],
        errorMessage: null,
      ),
    );

    final key = dateKeyOf(normalized);

    _summarySub = _repository
        .watchDailySummary(key)
        .listen(
          (summary) =>
              emit(state.copyWith(summary: summary, status: HomeStatus.ready)),
          onError: _onLoadError,
        );

    _logsSub = _repository
        .watchLogsForDay(key)
        .listen(
          (logs) => emit(state.copyWith(logs: logs)),
          onError: _onLoadError,
        );
  }

  /// Writes one log for the selected day. The trigger updates the summary.
  Future<void> addWater(int amountMl) async {
    try {
      await _repository.addWaterLog(
        amountMl: amountMl,
        dateKey: dateKeyOf(state.selectedDate),
      );
    } on HydrationException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  /// Deletes a log (undo). The trigger lowers the summary total.
  Future<void> deleteLog(String logId) async {
    try {
      await _repository.deleteWaterLog(logId);
    } on HydrationException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onLoadError(Object error, StackTrace _) {
    emit(
      state.copyWith(
        status: HomeStatus.error,
        errorMessage: error is HydrationException
            ? error.message
            : 'Could not load this day. Pull to retry.',
      ),
    );
  }

  @override
  Future<void> close() {
    _summarySub?.cancel();
    _logsSub?.cancel();
    return super.close();
  }
}
