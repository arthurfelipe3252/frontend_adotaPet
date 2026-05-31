import 'package:adota_pet/data/models/endereco_model.dart';
import 'package:adota_pet/data/models/usuario_model.dart';
import 'package:adota_pet/domain/entities/protetor_ong.dart';

class ProtetorOngResponseModel {
  final String id;
  final String cpfCnpj;
  final String? descricao;
  final String? telefoneContato;
  final String? imagemBase64;
  final UsuarioModel usuario;
  final EnderecoResponseModel? endereco;

  ProtetorOngResponseModel({
    required this.id,
    required this.cpfCnpj,
    this.descricao,
    this.telefoneContato,
    this.imagemBase64,
    required this.usuario,
    this.endereco,
  });

  factory ProtetorOngResponseModel.fromJson(Map<String, dynamic> json) {
    return ProtetorOngResponseModel(
      id: json['id'] as String,
      cpfCnpj: json['cpfCnpj'] as String,
      descricao: json['descricao'] as String?,
      telefoneContato: json['telefoneContato'] as String?,
      imagemBase64: json['imagemBase64'] as String?,
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
      endereco: json['endereco'] is Map<String, dynamic>
          ? EnderecoResponseModel.fromJson(
              json['endereco'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  ProtetorOng toEntity() {
    return ProtetorOng(
      id: id,
      cpfCnpj: cpfCnpj,
      descricao: descricao,
      telefoneContato: telefoneContato,
      imagemBase64: imagemBase64,
      usuario: usuario.toEntity(),
      endereco: endereco?.toEntity(),
    );
  }
}
