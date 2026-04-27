import 'package:adota_pet/domain/entities/endereco.dart';

class EnderecoRequestModel {
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;

  EnderecoRequestModel({
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
  });

  factory EnderecoRequestModel.fromEntity(Endereco e) {
    return EnderecoRequestModel(
      logradouro: e.logradouro,
      numero: e.numero,
      complemento: (e.complemento == null || e.complemento!.isEmpty)
          ? null
          : e.complemento,
      bairro: e.bairro,
      cidade: e.cidade,
      estado: e.estado,
      cep: e.cep,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logradouro': logradouro,
      'numero': numero,
      if (complemento != null) 'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
    };
  }
}

class EnderecoResponseModel {
  final String id;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;

  EnderecoResponseModel({
    required this.id,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
  });

  factory EnderecoResponseModel.fromJson(Map<String, dynamic> json) {
    return EnderecoResponseModel(
      id: json['id'] as String,
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      estado: json['estado'] as String,
      cep: json['cep'] as String,
    );
  }

  Endereco toEntity() {
    return Endereco(
      id: id,
      logradouro: logradouro,
      numero: numero,
      complemento: complemento,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      cep: cep,
    );
  }
}
