import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_exception.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_repository.dart';
import 'package:hydration_tracker/feature/assistant/presentation/chat_state.dart';

/// Drives the assistant message-list UI state for one selected day.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository, this._dateKey) : super(const ChatState());

  final ChatRepository _repository;
  final String _dateKey;

  int _counter = 0;

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      text: question,
    );
    // History is the conversation *before* this question; the data source
    // appends the question itself.
    final history = state.messages;

    emit(
      state.copyWith(
        messages: [...history, userMessage],
        isSending: true,
        errorMessage: null,
      ),
    );

    try {
      final reply = await _repository.sendMessage(
        question: question,
        dateKey: _dateKey,
        history: history,
      );
      emit(
        state.copyWith(messages: [...state.messages, reply], isSending: false),
      );
    } on ChatException catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.message));
    }
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
}
