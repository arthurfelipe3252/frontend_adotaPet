import 'package:adota_pet/domain/entities/endereco.dart';
import 'package:adota_pet/domain/entities/usuario.dart';

class ProtetorOng {
  final String id;
  final String cpfCnpj;
  final String? descricao;
  final String? telefoneContato;
  final String? imagemBase64;
  final Usuario usuario;
  final Endereco? endereco;

  const ProtetorOng({
    required this.id,
    required this.cpfCnpj,
    this.descricao,
    this.telefoneContato,
    this.imagemBase64,
    required this.usuario,
    this.endereco,
  });
}
