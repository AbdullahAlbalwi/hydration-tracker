import 'package:firebase_ai/firebase_ai.dart';
import 'package:hydration_tracker/feature/assistant/data/chat_message_dto.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_exception.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';

/// The only place that talks to Firebase AI Logic (`firebase_ai`).
///
/// Uses the Gemini Developer API backend (free tier) and calls the model
/// directly from the app — not via a Cloud Function, which is the point of the
/// AI Logic task. The model is created lazily and reused across turns.
class ChatRemoteDataSource {
  ChatRemoteDataSource({FirebaseAI? ai}) : _ai = ai ?? FirebaseAI.googleAI();

  final FirebaseAI _ai;
  GenerativeModel? _model;

  static const _modelName = 'gemini-2.5-flash';

  /// Scopes the assistant to general hydration/wellness guidance and makes it
  /// defer anything medical to a professional — no diagnoses or medical advice.
  static const _systemInstruction = '''
You are a friendly hydration and wellness assistant inside a water-tracking app.
Help the user understand their water intake and offer general, practical
hydration and wellness tips. Keep answers short, warm and encouraging.

Ground your answers in the hydration context you are given (today's logged
amount and goal) so advice is personal, not generic.

You are NOT a medical professional. If the user asks about symptoms, conditions,
medications, or anything clinical, gently remind them to consult a qualified
healthcare professional and do not provide a diagnosis or medical advice.''';

  GenerativeModel get _generativeModel => _model ??= _ai.generativeModel(
    model: _modelName,
    systemInstruction: Content.system(_systemInstruction),
  );

  /// Generates an assistant reply grounded in [contextText], with [history]
  /// for conversational continuity.
  Future<ChatMessageDto> generateReply({
    required String question,
    required String contextText,
    required List<ChatMessage> history,
  }) async {
    try {
      final contents = <Content>[
        for (final message in history)
          if (message.isUser)
            Content.text(message.text)
          else
            Content.model([TextPart(message.text)]),
        Content.text('$contextText\n\nUser question: $question'),
      ];

      final response = await _generativeModel.generateContent(contents);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const ChatException(
          'The assistant did not return a response. Please try again.',
        );
      }

      return ChatMessageDto(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.assistant.name,
        text: text,
      );
    } on ChatException {
      rethrow;
    } on FirebaseAIException catch (e) {
      throw ChatException(_friendlyMessage(e));
    }
  }

  String _friendlyMessage(FirebaseAIException e) {
    final message = e.message.toLowerCase();
    if (message.contains('quota') || message.contains('rate')) {
      return 'The assistant is busy right now. Please try again shortly.';
    }
    if (message.contains('network') || message.contains('unavailable')) {
      return 'Network error reaching the assistant. Check your connection.';
    }
    return 'The assistant is unavailable right now. Please try again.';
  }
}
