import 'package:adota_pet/domain/entities/usuario.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Usuario usuario;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.usuario,
  });

  factory AuthSession.fromExpiresIn({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    required Usuario usuario,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
      usuario: usuario,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
