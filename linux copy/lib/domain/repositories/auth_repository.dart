import 'package:adota_pet/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Faz login com email e senha. Retorna a sessão completa.
  /// Lança `Failure` em erro de credenciais ou rede.
  Future<AuthSession> login({required String email, required String senha});

  /// Tenta restaurar a sessão usando o refresh token salvo no storage.
  /// Retorna `null` se não há refresh token ou se ele já expirou (silencioso).
  Future<AuthSession?> tryRestoreSession();

  /// Renova o par de tokens usando o refresh token em memória.
  /// Retorna `true` se renovou com sucesso, `false` se falhou.
  /// Usado pelo interceptor 401 do HttpClient.
  Future<bool> tryRefresh();

  /// Encerra a sessão local e revoga o refresh token no backend (best-effort).
  Future<void> logout();
}
