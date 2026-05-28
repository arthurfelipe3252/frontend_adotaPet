import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/models/adoption_request_model.dart';

class AdoptionRequestRemoteDatasource {
  final HttpClient client;

  AdoptionRequestRemoteDatasource(this.client);

  Future<List<AdoptionRequestModel>> getAll() async {
    try {
      final response = await client.get('/adoptions');
      final data = response.data;

      if (data == null) return [];

      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else {
        return [];
      }

      final result = <AdoptionRequestModel>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(AdoptionRequestModel.fromJson(item));
          } catch (_) {}
        }
      }
      return result;
    } catch (e) {
      throw Failure(_extractMessage(e, 'Erro ao buscar solicitações de adoção'));
    }
  }

  Future<AdoptionRequestModel?> getById(String id) async {
    try {
      final response = await client.get('/adoptions/$id');
      if (response.data == null) return null;
      if (response.data is Map<String, dynamic>) {
        return AdoptionRequestModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Failure(_extractMessage(e, 'Erro ao buscar solicitação de adoção'));
    }
  }

  Future<AdoptionRequestModel> create(Map<String, dynamic> data) async {
    try {
      final response = await client.post('/adoptions', data: data);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        try {
          return AdoptionRequestModel.fromJson(body);
        } catch (_) {}
      }

      // Fallback: o backend retornou entidade com id=undefined (create sem id)
      return AdoptionRequestModel.fromParams(
        petId: data['petId'] as String? ?? '',
        adopterId: data['adopterId'] as String? ?? '',
        protetorId: data['protetorId'] as String?,
        mensagem: data['mensagem'] as String?,
        matchScore: (data['matchScore'] as num?)?.toInt(),
        questionario: data['questionario'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw Failure(_extractMessage(e, 'Erro ao criar solicitação de adoção'));
    }
  }

  Future<AdoptionRequestModel> updateStatus(String id, String status) async {
    try {
      final response = await client.patch(
        '/adoptions/$id/status',
        data: {'status': status},
      );
      final body = response.data;

      if (body is Map<String, dynamic>) {
        try {
          return AdoptionRequestModel.fromJson(body);
        } catch (_) {}
      }

      final fetched = await getById(id);
      if (fetched != null) return fetched;
      throw Failure('Solicitação não encontrada após atualização.');
    } catch (e) {
      throw Failure(_extractMessage(e, 'Erro ao atualizar status da solicitação'));
    }
  }

  Future<void> delete(String id) async {
    try {
      await client.delete('/adoptions/$id');
    } catch (e) {
      throw Failure(_extractMessage(e, 'Erro ao deletar solicitação de adoção'));
    }
  }

  String _extractMessage(Object e, String fallback) {
    final raw = e.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1)!;
    if (raw.startsWith('Failure(') && raw.endsWith(')')) {
      return raw.substring(8, raw.length - 1);
    }
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return fallback;
  }
}