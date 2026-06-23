import 'package:hydration_tracker/feature/assistant/data/chat_remote_data_source.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_repository.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';
import 'package:hydration_tracker/feature/hydration/domain/repositories/hydration_repository.dart';

/// Builds the grounding context from the hydration repository and delegates
/// generation to the AI data source.
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote, this._hydration);

  final ChatRemoteDataSource _remote;
  final HydrationRepository _hydration;

  @override
  Future<ChatMessage> sendMessage({
    required String question,
    required String dateKey,
    required List<ChatMessage> history,
  }) async {
    // Grounding data comes from the repository, not the widget.
    final summary = await _hydration.watchDailySummary(dateKey).first;
    final dto = await _remote.generateReply(
      question: question,
      contextText: _buildContext(dateKey, summary),
      history: history,
    );
    return dto.toDomain();
  }

  String _buildContext(String dateKey, DailySummary summary) {
    final percent = (summary.progress * 100).round();
    return 'Hydration context for $dateKey: the user has logged '
        '${summary.totalMl} ml of their ${summary.goalMl} ml goal '
        '($percent%), with ${summary.remainingMl} ml remaining and '
        '${summary.logCount} entries logged today.';
  }
}
