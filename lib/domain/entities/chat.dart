/// Prévia da última mensagem de uma conversa (para a lista de conversas).
class LastMessagePreview {
  final String content;
  final DateTime createdAt;
  final String senderTipo; // 'adotante' | 'protetor'

  const LastMessagePreview({
    required this.content,
    required this.createdAt,
    required this.senderTipo,
  });
}

class Conversation {
  final String id;
  final String adoptionRequestId;
  final String adopterId;
  final String protetorId;
  final String? adopterNome;
  final String? protetorNome;
  final bool isActive;

  /// Mensagens da outra parte ainda não lidas (do ponto de vista do usuário).
  final int unreadCount;
  final LastMessagePreview? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
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

  Conversation copyWith({bool? isActive, int? unreadCount}) {
    return Conversation(
      id: id,
      adoptionRequestId: adoptionRequestId,
      adopterId: adopterId,
      protetorId: protetorId,
      adopterNome: adopterNome,
      protetorNome: protetorNome,
      isActive: isActive ?? this.isActive,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderNome;
  final String senderTipo; // 'adotante' | 'protetor'
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
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
}
