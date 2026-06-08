class Conversation {
  final String id;
  final String adoptionRequestId;
  final String adopterId;
  final String protetorId;
  final String? adopterNome;
  final String? protetorNome;
  final bool isActive;
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
    required this.createdAt,
    required this.updatedAt,
  });
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
