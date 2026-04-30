import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/datasources/auth_cache_datasource.dart';
import 'package:adota_pet/data/datasources/auth_remote_datasource.dart';
import 'package:adota_pet/data/models/login_request_model.dart';
import 'package:adota_pet/domain/entities/auth_session.dart';
import 'package:adota_pet/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remote;
  final AuthCacheDatasource cache;
  final HttpClient httpClient;

  AuthRepositoryImpl({
    required this.remote,
    required this.cache,
    required this.httpClient,
  });

  @override
  Future<AuthSession> login({
    required String email,
    required String senha,
  }) async {
    final model = await remote.login(
      LoginRequestModel(email: email, senha: senha),
    );
    final session = model.toEntity();
    await _persistSession(session);
    return session;
  }

  @override
  Future<AuthSession?> tryRestoreSession() async {
    final refreshToken = cache.loadRefreshTokenFromDisk();
    if (refreshToken == null) return null;

    try {
      final model = await remote.refresh(refreshToken);
      final session = model.toEntity();
      await _persistSession(session);
      return session;
    } on Failure catch (f) {
      if (f.message == 'SESSION_EXPIRED') {
        // Token revogado/expirado: limpa storage silenciosamente.
        await cache.clear();
        return null;
      }
      // Erro de rede: mantém storage (próxima abertura tenta de novo).
      return null;
    }
  }

  @override
  Future<bool> tryRefresh() async {
    final refreshToken = cache.refreshToken;
    if (refreshToken == null) return false;

    try {
      final model = await remote.refresh(refreshToken);
      final session = model.toEntity();
      await _persistSession(session);
      return true;
    } on Failure catch (f) {
      if (f.message == 'SESSION_EXPIRED') {
        await cache.clear();
        httpClient.setAccessToken(null);
      }
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = cache.refreshToken;
    if (refreshToken != null) {
      try {
        await remote.logout(refreshToken);
      } catch (_) {
        // Best-effort: ignora erro ao revogar no backend; logout local sempre acontece.
      }
    }
    await cache.clear();
    httpClient.setAccessToken(null);
  }

  Future<void> _persistSession(AuthSession session) async {
    await cache.save(session);
    httpClient.setAccessToken(session.accessToken);
  }
}
