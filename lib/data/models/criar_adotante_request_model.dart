import 'dart:convert';
import 'dart:typed_data';

import 'package:adota_pet/data/models/endereco_model.dart';
import 'package:adota_pet/domain/entities/criar_adotante_params.dart';

class CriarAdotanteRequestModel {
  final String nome;
  final String email;
  final String senha;
  final String cpf;
  final EnderecoRequestModel endereco;
  final String? telefone;
  final Uint8List? imagemBytes;

  CriarAdotanteRequestModel({
    required this.nome,
    required this.email,
    required this.senha,
    required this.cpf,
    required this.endereco,
    this.telefone,
    this.imagemBytes,
  });

  factory CriarAdotanteRequestModel.fromParams(CriarAdotanteParams params) {
    return CriarAdotanteRequestModel(
      nome: params.nome,
      email: params.email,
      senha: params.senha,
      cpf: params.cpf,
      endereco: EnderecoRequestModel.fromEntity(params.endereco),
      telefone: params.telefone,
      imagemBytes: params.imagemBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'cpf': cpf,
      'endereco': endereco.toJson(),
      if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
      if (imagemBytes != null) 'imagemBase64': base64Encode(imagemBytes!),
    };
  }
}
