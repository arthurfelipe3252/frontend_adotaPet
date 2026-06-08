import 'dart:async';

import 'package:flutter/material.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/chat_remote_datasource.dart';
import 'package:adota_pet/domain/entities/chat.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRemoteDatasource datasource;
  ChatViewModel(this.datasource);

  // ── Estado ─────────────────────────────────────────────────────────────────

  bool isLoadingConversations = false;
  bool isLoadingMessages = false;
  bool isSending = false;
  String? error;

  List<Conversation> conversations = [];
  Conversation? activeConversation;
  List<ChatMessage> messages = [];

  Timer? _pollTimer;

  String _msg(Object e) => e is Failure ? e.message : e.toString();

  // ── Conversas ──────────────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    isLoadingConversations = true;
    error = null;
    notifyListeners();
    try {
      final models = await datasource.getConversations();
      conversations = models.map((m) => m.toEntity()).toList();
    } catch (e) {
      error = _msg(e);
    }
    isLoadingConversations = false;
    notifyListeners();
  }

  Future<void> openConversation(String conversationId) async {
    stopPolling();
    isLoadingMessages = true;
    error = null;
    notifyListeners();

    try {
      final conv = await datasource.getConversationById(conversationId);
      activeConversation = conv.toEntity();
      await _fetchMessages();
      _startPolling();
    } catch (e) {
      error = _msg(e);
    }

    isLoadingMessages = false;
    notifyListeners();
  }

  Future<Conversation?> createConversation(String adoptionRequestId) async {
    try {
      final model = await datasource.createConversation(adoptionRequestId);
      final conv = model.toEntity();
      conversations.insert(0, conv);
      notifyListeners();
      return conv;
    } catch (e) {
      error = _msg(e);
      notifyListeners();
      return null;
    }
  }

  // ── Mensagens ──────────────────────────────────────────────────────────────

  Future<void> _fetchMessages() async {
    if (activeConversation == null) return;
    try {
      final models = await datasource.getMessages(activeConversation!.id);
      messages = models.map((m) => m.toEntity()).toList();
      notifyListeners();
    } catch (e) {
      // Mantém mensagens existentes em caso de erro de polling
    }
  }

  Future<bool> sendMessage(String content) async {
    if (activeConversation == null || content.trim().isEmpty) return false;
    isSending = true;
    notifyListeners();
    try {
      final model = await datasource.sendMessage(
        activeConversation!.id,
        content.trim(),
      );
      messages.add(model.toEntity());
      isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = _msg(e);
      isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markMessageRead(String messageId) async {
    await datasource.markAsRead(messageId);
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMessages();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void closeConversation() {
    stopPolling();
    activeConversation = null;
    messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
