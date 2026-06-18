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
  bool isClosing = false;
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
      // A API já entrega ordenado por última atividade (lastMessage.createdAt
      // desc), então não reordenamos no cliente.
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
      // Ao abrir, zera as não-lidas (backend marca tudo da outra parte como
      // lido numa chamada só; espelhamos localmente sem refetch).
      _markConversationRead(conversationId);
    } catch (e) {
      error = _msg(e);
    }

    isLoadingMessages = false;
    notifyListeners();
  }

  /// Marca a conversa como lida no backend e zera o `unreadCount` local
  /// (na lista e na conversa ativa). Falha silenciosa.
  Future<void> _markConversationRead(String conversationId) async {
    await datasource.markConversationRead(conversationId);
    conversations = conversations
        .map((c) => c.id == conversationId ? c.copyWith(unreadCount: 0) : c)
        .toList();
    if (activeConversation?.id == conversationId) {
      activeConversation = activeConversation!.copyWith(unreadCount: 0);
    }
    notifyListeners();
  }

  /// Abre OU cria a conversa de uma solicitação. Procura primeiro na lista já
  /// carregada (por `adoptionRequestId`); se não achar, tenta criar; se a
  /// criação falhar (ex.: 409 porque a conversa existe mas a lista estava
  /// desatualizada), recarrega e procura de novo. Retorna `null` em falha real.
  Future<Conversation?> getOrCreateConversation(String adoptionRequestId) async {
    Conversation? find() {
      for (final c in conversations) {
        if (c.adoptionRequestId == adoptionRequestId) return c;
      }
      return null;
    }

    if (conversations.isEmpty) await loadConversations();
    final existing = find();
    if (existing != null) return existing;

    final created = await createConversation(adoptionRequestId);
    if (created != null) return created;

    // Falhou ao criar (provável 409): sincroniza e tenta achar de novo.
    await loadConversations();
    return find();
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

  /// Encerra a conversa ativa no backend (`PATCH .../active` com isActive=false).
  /// Mantém a conversa aberta (histórico visível); apenas marca como encerrada
  /// e atualiza a lista. Retorna `true` em sucesso.
  Future<bool> endConversation() async {
    final conv = activeConversation;
    if (conv == null) return false;
    isClosing = true;
    notifyListeners();
    try {
      final updated = (await datasource.setActive(conv.id, false)).toEntity();
      activeConversation = updated;
      conversations = conversations
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      stopPolling();
      isClosing = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = _msg(e);
      isClosing = false;
      notifyListeners();
      return false;
    }
  }

  /// Fecha a conversa na UI (volta para a lista) — NÃO encerra no backend.
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
