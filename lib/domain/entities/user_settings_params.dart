import 'dart:typed_data';

import 'package:adota_pet/domain/entities/endereco.dart';

class AtualizarAdotanteParams {
  final String? nome;
  final String? telefone;
  final Uint8List? imagemBytes;
  final bool removerImagem;
  final Endereco? endereco;

  const AtualizarAdotanteParams({
    this.nome,
    this.telefone,
    this.imagemBytes,
    this.removerImagem = false,
    this.endereco,
  });
}

class AtualizarProtetorOngParams {
  final String? nome;
  final String? telefone;
  final String? descricao;
  final String? telefoneContato;
  final Uint8List? imagemBytes;
  final bool removerImagem;
  final Endereco? endereco;

  const AtualizarProtetorOngParams({
    this.nome,
    this.telefone,
    this.descricao,
    this.telefoneContato,
    this.imagemBytes,
    this.removerImagem = false,
    this.endereco,
  });
}

class AlterarSenhaParams {
  final String senhaAtual;
  final String senhaNova;

  const AlterarSenhaParams({required this.senhaAtual, required this.senhaNova});
}
