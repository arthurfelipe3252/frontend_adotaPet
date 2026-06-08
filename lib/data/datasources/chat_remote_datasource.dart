import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/datasources/_dio_error_helper.dart';
import 'package:adota_pet/data/models/chat_model.dart';

class ChatRemoteDatasource {
  final HttpClient client;
  ChatRemoteDatasource(this.client);

  // ── Conversas ─────────────────────────────────────────────────────────────

  Future<List<ConversationModel>> getConversations() async {
    try {
      final res = await client.get('/chat/conversations');
      final list = res.data is List ? res.data as List : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        403: 'Você não tem permissão para acessar as conversas.',
      });
    } catch (e) {
      throw Failure('Não foi possível carregar as conversas.');
    }
  }

  Future<ConversationModel> getConversationById(String id) async {
    try {
      final res = await client.get('/chat/conversations/$id');
      return ConversationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        404: 'Conversa não encontrada.',
        403: 'Você não tem acesso a esta conversa.',
      });
    } catch (e) {
      throw Failure('Não foi possível carregar a conversa.');
    }
  }

  Future<ConversationModel> createConversation(String adoptionRequestId) async {
    try {
      final res = await client.post('/chat/conversations', data: {
        'adoptionRequestId': adoptionRequestId,
      });
      return ConversationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        409: 'Já existe uma conversa para esta solicitação.',
        403: 'Você não faz parte desta solicitação de adoção.',
      });
    } catch (e) {
      throw Failure('Não foi possível criar a conversa.');
    }
  }

  // ── Mensagens ─────────────────────────────────────────────────────────────

  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.get(
        '/chat/conversations/$conversationId/messages?limit=$limit&offset=$offset',
      );
      final list = res.data is List ? res.data as List : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        403: 'Você não tem acesso a esta conversa.',
        404: 'Conversa não encontrada.',
      });
    } catch (e) {
      throw Failure('Não foi possível carregar as mensagens.');
    }
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final res = await client.post(
        '/chat/conversations/$conversationId/messages',
        data: {'content': content},
      );
      return ChatMessageModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        403: 'Você não pode enviar mensagens nesta conversa.',
        404: 'Conversa não encontrada.',
      });
    } catch (e) {
      throw Failure('Não foi possível enviar a mensagem.');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await client.patch('/chat/messages/$messageId/read', data: {
        'isRead': true,
      });
    } on DioException catch (_) {
      // Falha silenciosa — não bloqueia a UX
    } catch (_) {}
  }
}
