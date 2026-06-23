import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/core/date_key.dart';
import 'package:hydration_tracker/feature/hydration/domain/hydration_exception.dart';
import 'package:hydration_tracker/feature/hydration/domain/repositories/hydration_repository.dart';
import 'package:hydration_tracker/feature/hydration/presentation/cubit/insights_state.dart';

/// Loads the weekly insights by calling the `getWeeklyInsights` callable.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._repository) : super(const InsightsState()) {
    load();
  }

  final HydrationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: InsightsStatus.loading, errorMessage: null));
    try {
      final insights = await _repository.getWeeklyInsights(
        today: dateKeyOf(DateTime.now()),
      );
      emit(state.copyWith(status: InsightsStatus.ready, insights: insights));
    } on HydrationException catch (e) {
      emit(
        state.copyWith(status: InsightsStatus.error, errorMessage: e.message),
      );
    }
  }
}
