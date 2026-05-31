import 'package:adota_pet/core/storage/auth_storage.dart';
import 'package:adota_pet/domain/entities/auth_session.dart';

/// Cache em memória da sessão atual + persistência do refresh token.
/// Access token vive só em memória (TTL curto regenerado por refresh).
class AuthCacheDatasource {
  final AuthStorage storage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  AuthCacheDatasource(this.storage);

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get expiresAt => _expiresAt;
  bool get hasMemorySession => _accessToken != null && _refreshToken != null;

  Future<void> save(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _expiresAt = session.expiresAt;
    await storage.saveRefreshToken(session.refreshToken);
  }

  String? loadRefreshTokenFromDisk() {
    final token = storage.readRefreshToken();
    if (token == null || token.isEmpty) return null;
    _refreshToken = token;
    return token;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    await storage.clear();
  }
}
