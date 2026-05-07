import 'package:adota_pet/domain/entities/usuario.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String tipoUsuario;
  final String? telefone;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipoUsuario: json['tipoUsuario'] as String,
      telefone: json['telefone'] is String ? json['telefone'] as String : null,
    );
  }

  Usuario toEntity() {
    return Usuario(
      id: id,
      nome: nome,
      email: email,
      tipoUsuario: tipoUsuario,
      telefone: telefone,
    );
  }
}
