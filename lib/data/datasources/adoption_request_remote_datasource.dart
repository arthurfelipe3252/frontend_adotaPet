import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/data/models/adoption_request_model.dart';

class AdoptionRequestRemoteDatasource {
  final HttpClient client;

  AdoptionRequestRemoteDatasource(this.client);

  Future<List<AdoptionRequestModel>> getAll() async {
    try {
      final response = await client.get('/adoptions');
      final list = response.data as List<dynamic>;
      return list
          .map((json) => AdoptionRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Failure('Erro ao buscar solicitações de adoção: $e');
    }
  }
  
  Future<AdoptionRequestModel?> getById(String id) async {
    try {
      final response = await client.get('/adoptions/$id');
      if (response.data == null) return null;
      return AdoptionRequestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Failure('Erro ao buscar solicitação de adoção: $e');
    }
  }

  Future<AdoptionRequestModel> create(Map<String, dynamic> data) async {
    try {
      final response = await client.post('/adoptions', data: data);
      return AdoptionRequestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Failure('Erro ao criar solicitação de adoção: $e');
    }
  }

  Future<AdoptionRequestModel> updateStatus(String id, String status) async {
    try {
      final response = await client.patch('/adoptions/$id/status', data: {'status': status});
      return AdoptionRequestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Failure('Erro ao atualizar status da solicitação de adoção: $e');
    }
  }
  
  Future<void> delete(String id) async {
    try {
      await client.delete('/adoptions/$id');
    } catch (e) {
      throw Failure('Erro ao deletar solicitação de adoção: $e');
    }
  }
}
