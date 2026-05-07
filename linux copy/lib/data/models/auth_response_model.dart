import 'package:adota_pet/data/models/usuario_model.dart';
import 'package:adota_pet/domain/entities/auth_session.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UsuarioModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: UsuarioModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AuthSession toEntity() {
    return AuthSession.fromExpiresIn(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn,
      usuario: user.toEntity(),
    );
  }
}
