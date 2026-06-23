import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';

part 'chat_state.freezed.dart';

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
    @Default(false) bool isSending,
    String? errorMessage,
  }) = _ChatState;
}
