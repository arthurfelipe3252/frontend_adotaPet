import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/datasources/_dio_error_helper.dart';
import 'package:adota_pet/data/models/auth_response_model.dart';
import 'package:adota_pet/data/models/login_request_model.dart';

class AuthRemoteDatasource {
  final HttpClient client;

  AuthRemoteDatasource(this.client);

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await client.post(
        '/users/auth/login',
        data: request.toJson(),
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(
        e,
        customByStatus: {
          400: 'Verifique os dados informados.',
          401: 'Email ou senha inválidos.',
        },
      );
    }
  }

  Future<AuthResponseModel> refresh(String refreshToken) async {
    try {
      final response = await client.post(
        '/users/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 401 no refresh = sessão expirada/revogada. Sentinel pro repository.
      if (e.response?.statusCode == 401) {
        throw Failure('SESSION_EXPIRED');
      }
      throw failureFromDio(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    await client.post(
      '/users/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
