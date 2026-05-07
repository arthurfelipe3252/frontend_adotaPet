import 'dart:convert';
import 'dart:typed_data';

import 'package:adota_pet/data/models/endereco_model.dart';
import 'package:adota_pet/domain/entities/criar_protetor_ong_params.dart';

class CriarProtetorOngRequestModel {
  final String nome;
  final String email;
  final String senha;
  final String tipoUsuario;
  final String cpfCnpj;
  final Uint8List documentoBytes;
  final EnderecoRequestModel endereco;
  final String? telefone;
  final String? telefoneContato;
  final String? descricao;
  final Uint8List? imagemBytes;

  CriarProtetorOngRequestModel({
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipoUsuario,
    required this.cpfCnpj,
    required this.documentoBytes,
    required this.endereco,
    this.telefone,
    this.telefoneContato,
    this.descricao,
    this.imagemBytes,
  });

  factory CriarProtetorOngRequestModel.fromParams(
    CriarProtetorOngParams params,
  ) {
    return CriarProtetorOngRequestModel(
      nome: params.nome,
      email: params.email,
      senha: params.senha,
      tipoUsuario: params.tipoUsuario,
      cpfCnpj: params.cpfCnpj,
      documentoBytes: params.documentoBytes,
      endereco: EnderecoRequestModel.fromEntity(params.endereco),
      telefone: params.telefone,
      telefoneContato: params.telefoneContato,
      descricao: params.descricao,
      imagemBytes: params.imagemBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'tipoUsuario': tipoUsuario,
      'cpfCnpj': cpfCnpj,
      'documentoComprobatorio': base64Encode(documentoBytes),
      'endereco': endereco.toJson(),
      if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
      if (telefoneContato != null && telefoneContato!.isNotEmpty)
        'telefoneContato': telefoneContato,
      if (descricao != null && descricao!.isNotEmpty) 'descricao': descricao,
      if (imagemBytes != null) 'imagemBase64': base64Encode(imagemBytes!),
    };
  }
}
