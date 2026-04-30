import 'package:adota_pet/domain/entities/endereco.dart';

class CepResponseModel {
  final bool erro;
  final String? cep;
  final String? logradouro;
  final String? bairro;
  final String? localidade;
  final String? uf;

  CepResponseModel({
    required this.erro,
    this.cep,
    this.logradouro,
    this.bairro,
    this.localidade,
    this.uf,
  });

  factory CepResponseModel.fromJson(Map<String, dynamic> json) {
    return CepResponseModel(
      erro: json['erro'] == true || json['erro'] == 'true',
      cep: json['cep'] as String?,
      logradouro: json['logradouro'] as String?,
      bairro: json['bairro'] as String?,
      localidade: json['localidade'] as String?,
      uf: json['uf'] as String?,
    );
  }

  Endereco toEntity() {
    final cleanCep = (cep ?? '').replaceAll(RegExp(r'\D'), '');
    return Endereco(
      logradouro: logradouro ?? '',
      numero: '',
      bairro: bairro ?? '',
      cidade: localidade ?? '',
      estado: uf ?? '',
      cep: cleanCep,
    );
  }
}
