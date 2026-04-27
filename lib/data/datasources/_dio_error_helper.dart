import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';

/// Converte um `DioException` em `Failure` com mensagem amigável.
///
/// Aplica em ordem:
/// 1. Sem resposta (timeout, conexão recusada, offline).
/// 2. 5xx (erro do servidor).
/// 3. Mensagem custom por status (`customByStatus[status]`).
/// 4. `response.data['message']` quando string ou primeiro item de array.
/// 5. Fallback genérico.
Failure failureFromDio(DioException e, {Map<int, String>? customByStatus}) {
  if (e.response == null) {
    return Failure('Sem conexão. Verifique sua internet e tente novamente.');
  }

  final status = e.response!.statusCode ?? 0;

  if (status >= 500 && status < 600) {
    return Failure('Erro no servidor. Tente novamente em instantes.');
  }

  if (customByStatus != null && customByStatus.containsKey(status)) {
    return Failure(customByStatus[status]!);
  }

  final backendMessage = extractBackendMessage(e.response?.data);
  if (backendMessage != null) {
    return Failure(backendMessage);
  }

  return Failure('Não foi possível concluir a operação.');
}

/// Extrai a primeira mensagem útil do payload de erro do NestJS.
/// Retorna `null` se não for possível.
String? extractBackendMessage(dynamic data) {
  if (data is! Map) return null;
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }
  if (message is List && message.isNotEmpty) {
    final first = message.first;
    if (first is String && first.trim().isNotEmpty) {
      return first;
    }
  }
  return null;
}
