import 'package:dio/dio.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/datasources/_dio_error_helper.dart';
import 'package:adota_pet/data/models/match_model.dart';

class MatchRemoteDatasource {
  final HttpClient client;
  MatchRemoteDatasource(this.client);

  /// Salva (cria ou atualiza) o questionário do adotante autenticado.
  Future<QuestionarioMatchModel> salvarQuestionario({
    required String tipoMoradia,
    required String disponibilidade,
    required String experienciaPrevia,
    required String criancasEmCasa,
    required String outrosPets,
    required String perfilCompanheiro,
  }) async {
    try {
      final res = await client.post('/match/questionario', data: {
        'tipoMoradia': tipoMoradia,
        'disponibilidade': disponibilidade,
        'experienciaPrevia': experienciaPrevia,
        'criancasEmCasa': criancasEmCasa,
        'outrosPets': outrosPets,
        'perfilCompanheiro': perfilCompanheiro,
      });
      return QuestionarioMatchModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        400: 'Respostas inválidas. Revise o questionário e tente novamente.',
      });
    } catch (e) {
      throw Failure('Não foi possível salvar suas respostas.');
    }
  }

  /// Busca o questionário já salvo do adotante autenticado.
  /// Retorna `null` se ele ainda não respondeu (404 do backend).
  Future<QuestionarioMatchModel?> buscarMeuQuestionario() async {
    try {
      final res = await client.get('/match/questionario');
      return QuestionarioMatchModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw failureFromDio(e);
    } catch (e) {
      throw Failure('Não foi possível carregar seu questionário.');
    }
  }

  /// Calcula e retorna os pets compatíveis, ordenados por score.
  Future<MatchResultModel> calcularMeuMatch() async {
    try {
      final res = await client.get('/match/resultado');
      return MatchResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw failureFromDio(e, customByStatus: {
        404: 'Responda o questionário antes de ver seus matches.',
      });
    } catch (e) {
      throw Failure('Não foi possível calcular seus matches.');
    }
  }

  /// Remove o questionário, permitindo refazer o quiz do zero.
  Future<void> removerQuestionario() async {
    try {
      await client.delete('/match/questionario');
    } on DioException catch (e) {
      throw failureFromDio(e);
    } catch (e) {
      throw Failure('Não foi possível reiniciar o questionário.');
    }
  }
}
