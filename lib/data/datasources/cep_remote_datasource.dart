import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/models/cep_response_model.dart';

/// Datasource do ViaCEP. Usa Dio próprio (host externo, não usa o HttpClient da API).
class CepRemoteDatasource {
  final Dio _dio;

  CepRemoteDatasource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://viacep.com.br',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

  /// Retorna `null` quando o CEP não existe (ViaCEP responde `{"erro": true}`).
  /// Lança `Failure` em erro de rede (capturado/silenciado pelo repository).
  Future<CepResponseModel?> consultar(String cep) async {
    try {
      final response = await _dio.get<dynamic>('/ws/$cep/json/');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final model = CepResponseModel.fromJson(data);
      if (model.erro) return null;
      return model;
    } on DioException {
      throw Failure('Não foi possível consultar o CEP.');
    }
  }
}
