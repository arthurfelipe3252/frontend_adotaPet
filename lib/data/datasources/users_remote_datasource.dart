import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/datasources/_dio_error_helper.dart';
import 'package:adota_pet/data/models/criar_protetor_ong_request_model.dart';
import 'package:adota_pet/data/models/protetor_ong_model.dart';

class UsersRemoteDatasource {
  final HttpClient client;

  UsersRemoteDatasource(this.client);

  Future<ProtetorOngResponseModel> criarProtetorOng(
    CriarProtetorOngRequestModel request,
  ) async {
    try {
      final response = await client.post(
        '/users/protetores-ongs',
        data: request.toJson(),
      );
      return ProtetorOngResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // 409 vira ConflictFailure: o repository decide qual field destacar.
      if (e.response?.statusCode == 409) {
        final msg = extractBackendMessage(e.response?.data) ?? '';
        throw ConflictFailure(msg);
      }
      throw failureFromDio(
        e,
        customByStatus: {400: 'Verifique os dados informados.'},
      );
    }
  }

  Future<ProtetorOngResponseModel> getMe() async {
    try {
      final response = await client.get('/users/protetores-ongs/me');
      return ProtetorOngResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw failureFromDio(
        e,
        customByStatus: {
          401: 'Sua sessão expirou. Faça login novamente.',
          403: 'Acesso negado a este perfil.',
          404: 'Perfil não encontrado.',
        },
      );
    }
  }
}
