import 'dart:typed_data';

import 'package:adota_pet/domain/entities/endereco.dart';

class CriarAdotanteParams {
  final String nome;
  final String email;
  final String senha;
  final String cpf;
  final Endereco endereco;
  final String? telefone;
  final Uint8List? imagemBytes;
  final String? imagemFilename;

  const CriarAdotanteParams({
    required this.nome,
    required this.email,
    required this.senha,
    required this.cpf,
    required this.endereco,
    this.telefone,
    this.imagemBytes,
    this.imagemFilename,
  });
}
