import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

/// Who authored a chat message.
enum ChatRole { user, assistant }

/// A single message in the hydration assistant conversation.
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required ChatRole role,
    required String text,
  }) = _ChatMessage;

  const ChatMessage._();

  bool get isUser => role == ChatRole.user;
}
