import 'package:adota_pet/domain/entities/chat.dart';

class ConversationModel {
  final String id;
  final String adoptionRequestId;
  final String adopterId;
  final String protetorId;
  final String? adopterNome;
  final String? protetorNome;
  final bool isActive;
  final int unreadCount;
  final LastMessagePreview? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.adoptionRequestId,
    required this.adopterId,
    required this.protetorId,
    this.adopterNome,
    this.protetorNome,
    required this.isActive,
    this.unreadCount = 0,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      adoptionRequestId: json['adoptionRequestId'] as String,
      adopterId: json['adopterId'] as String,
      protetorId: json['protetorId'] as String,
      adopterNome: (json['adopter'] as Map<String, dynamic>?)?['nome'] as String?,
      protetorNome: (json['protetor'] as Map<String, dynamic>?)?['nome'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessage: _lastMessage(json['lastMessage']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static LastMessagePreview? _lastMessage(dynamic v) {
    if (v is! Map) return null;
    final content = v['content'] as String?;
    if (content == null) return null;
    return LastMessagePreview(
      content: content,
      createdAt: DateTime.tryParse(v['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      senderTipo: v['senderTipo'] as String? ?? 'adotante',
    );
  }

  Conversation toEntity() => Conversation(
        id: id,
        adoptionRequestId: adoptionRequestId,
        adopterId: adopterId,
        protetorId: protetorId,
        adopterNome: adopterNome,
        protetorNome: protetorNome,
        isActive: isActive,
        unreadCount: unreadCount,
        lastMessage: lastMessage,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderNome;
  final String senderTipo;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderNome,
    required this.senderTipo,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderNome: sender?['nome'] as String?,
      senderTipo: sender?['tipo'] as String? ?? 'adotante',
      content: json['content'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  ChatMessage toEntity() => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderNome: senderNome,
        senderTipo: senderTipo,
        content: content,
        isRead: isRead,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
