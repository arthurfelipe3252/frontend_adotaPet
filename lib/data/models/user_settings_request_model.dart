import 'dart:convert';

import 'package:adota_pet/data/models/endereco_model.dart';
import 'package:adota_pet/domain/entities/user_settings_params.dart';

class AtualizarAdotanteRequestModel {
  final AtualizarAdotanteParams params;

  AtualizarAdotanteRequestModel(this.params);

  Map<String, dynamic> toJson() {
    return {
      if (params.nome != null) 'nome': params.nome,
      if (params.telefone != null) 'telefone': params.telefone,
      if (params.imagemBytes != null)
        'imagemBase64': base64Encode(params.imagemBytes!),
      if (params.imagemBytes == null && params.removerImagem)
        'imagemBase64': '',
      if (params.endereco != null)
        'endereco': EnderecoRequestModel.fromEntity(params.endereco!).toJson(),
    };
  }
}

class AtualizarProtetorOngRequestModel {
  final AtualizarProtetorOngParams params;

  AtualizarProtetorOngRequestModel(this.params);

  Map<String, dynamic> toJson() {
    return {
      if (params.nome != null) 'nome': params.nome,
      if (params.telefone != null) 'telefone': params.telefone,
      if (params.descricao != null) 'descricao': params.descricao,
      if (params.telefoneContato != null)
        'telefoneContato': params.telefoneContato,
      if (params.imagemBytes != null)
        'imagemBase64': base64Encode(params.imagemBytes!),
      if (params.imagemBytes == null && params.removerImagem)
        'imagemBase64': '',
      if (params.endereco != null)
        'endereco': EnderecoRequestModel.fromEntity(params.endereco!).toJson(),
    };
  }
}

class AlterarSenhaRequestModel {
  final AlterarSenhaParams params;

  AlterarSenhaRequestModel(this.params);

  Map<String, dynamic> toJson() {
    return {'senhaAtual': params.senhaAtual, 'senhaNova': params.senhaNova};
  }
}
