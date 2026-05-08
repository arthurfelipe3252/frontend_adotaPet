import 'package:adota_pet/domain/entities/endereco.dart';
import 'package:adota_pet/domain/entities/usuario.dart';

class Adotante {
  final String id;
  final String cpf;
  final String? imagemBase64;
  final Usuario usuario;
  final Endereco? endereco;

  const Adotante({
    required this.id,
    required this.cpf,
    this.imagemBase64,
    required this.usuario,
    this.endereco,
  });
}
