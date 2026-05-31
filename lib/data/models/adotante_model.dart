import 'package:adota_pet/data/models/endereco_model.dart';
import 'package:adota_pet/data/models/usuario_model.dart';
import 'package:adota_pet/domain/entities/adotante.dart';

class AdotanteResponseModel {
  final String id;
  final String cpf;
  final String? imagemBase64;
  final UsuarioModel usuario;
  final EnderecoResponseModel? endereco;

  AdotanteResponseModel({
    required this.id,
    required this.cpf,
    this.imagemBase64,
    required this.usuario,
    this.endereco,
  });

  factory AdotanteResponseModel.fromJson(Map<String, dynamic> json) {
    return AdotanteResponseModel(
      id: json['id'] as String,
      cpf: json['cpf'] as String,
      imagemBase64: json['imagemBase64'] as String?,
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
      endereco: json['endereco'] is Map<String, dynamic>
          ? EnderecoResponseModel.fromJson(
              json['endereco'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Adotante toEntity() {
    return Adotante(
      id: id,
      cpf: cpf,
      imagemBase64: imagemBase64,
      usuario: usuario.toEntity(),
      endereco: endereco?.toEntity(),
    );
  }
}
