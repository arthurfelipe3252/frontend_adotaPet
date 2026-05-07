import 'dart:typed_data';

import 'package:adota_pet/domain/entities/endereco.dart';

class CriarProtetorOngParams {
  final String nome;
  final String email;
  final String senha;
  final String tipoUsuario;
  final String cpfCnpj;
  final Uint8List documentoBytes;
  final String documentoFilename;
  final Endereco endereco;
  final String? telefone;
  final String? telefoneContato;
  final String? descricao;
  final Uint8List? imagemBytes;

  const CriarProtetorOngParams({
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipoUsuario,
    required this.cpfCnpj,
    required this.documentoBytes,
    required this.documentoFilename,
    required this.endereco,
    this.telefone,
    this.telefoneContato,
    this.descricao,
    this.imagemBytes,
  });
}
