import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Wrapper de Dio com baseUrl por plataforma e interceptor 401.
///
/// O `onUnauthorized` é plugado pelo `main.dart` apontando para o método
/// de refresh do AuthRepository, mantendo o cliente HTTP ignorante da
/// camada de dados.
class HttpClient {
  final Dio _dio;

  /// Callback chamado quando uma request retorna 401. Se retornar `true`,
  /// a request original é refeita automaticamente com o novo token.
  Future<bool> Function()? onUnauthorized;

  bool _isRefreshing = false;

  HttpClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kIsWeb
              ? 'http://localhost:3000/api/v1'
              : 'http://10.0.2.2:3000/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final isRefreshEndpoint = error.requestOptions.path.contains(
            '/auth/refresh',
          );

          if (status == 401 &&
              onUnauthorized != null &&
              !_isRefreshing &&
              !isRefreshEndpoint) {
            _isRefreshing = true;
            try {
              final refreshed = await onUnauthorized!.call();
              if (refreshed) {
                final original = error.requestOptions;
                final newAuth = _dio.options.headers['Authorization'];
                if (newAuth != null) {
                  original.headers['Authorization'] = newAuth;
                }
                final response = await _dio.fetch<dynamic>(original);
                handler.resolve(response);
                return;
              }
            } catch (_) {
              // Ignora — propaga o 401 original abaixo.
            } finally {
              _isRefreshing = false;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  void setAccessToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
