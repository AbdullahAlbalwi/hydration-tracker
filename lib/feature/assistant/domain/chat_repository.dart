import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';

/// Contract for the hydration assistant.
///
/// The grounding data (the selected day's totals) is gathered inside the
/// implementation from the hydration repository — the UI only supplies the
/// question, the day in scope, and the running history.
abstract interface class ChatRepository {
  /// Sends [question] grounded in the totals for [dateKey], using prior
  /// [history] for conversational context. Returns the assistant's reply.
  /// Throws [ChatException] on failure.
  Future<ChatMessage> sendMessage({
    required String question,
    required String dateKey,
    required List<ChatMessage> history,
  });
}
