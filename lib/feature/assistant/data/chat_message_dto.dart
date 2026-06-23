import 'package:hydration_tracker/feature/assistant/domain/chat_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message_dto.g.dart';

/// DTO for a chat message.
///
/// The conversation is kept in-session (persistence is optional), but routing
/// the model reply through a DTO keeps the data-source -> repository -> entity
/// mapping consistent with the rest of the app and leaves a clean seam for
/// optional Firestore persistence later.
@JsonSerializable()
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.role,
    required this.text,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  factory ChatMessageDto.fromDomain(ChatMessage message) => ChatMessageDto(
    id: message.id,
    role: message.role.name,
    text: message.text,
  );

  final String id;
  final String role;
  final String text;

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);

  ChatMessage toDomain() => ChatMessage(
    id: id,
    role: role == ChatRole.assistant.name ? ChatRole.assistant : ChatRole.user,
    text: text,
  );
}
