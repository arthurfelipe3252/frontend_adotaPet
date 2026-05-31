import '../../core/network/http_client.dart';
import '../models/pet_model.dart';

class PetRemoteDatasource {
  final HttpClient client;

  PetRemoteDatasource(this.client);

  Future<List<PetModel>> getPets({
    String? especie,
    String? porte,
    String? status,
  }) async {
    final params = <String, String>{};
    if (especie != null) params['especie'] = especie;
    if (porte != null) params['porte'] = porte;
    if (status != null) params['status'] = status;

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = query.isEmpty ? '/pets' : '/pets?$query';

    final response = await client.get(path);
    final List data = response.data;
    return data.map((json) => PetModel.fromJson(json)).toList();
  }

  Future<PetModel> getPetById(String id) async {
    final response = await client.get('/pets/$id');
    return PetModel.fromJson(response.data);
  }

  Future<PetModel> createPet(Map<String, dynamic> data) async {
    final response = await client.post('/pets', data: data);
    return PetModel.fromJson(response.data);
  }

  Future<PetModel> updatePet(String id, Map<String, dynamic> data) async {
    final response = await client.patch('/pets/$id', data: data);
    return PetModel.fromJson(response.data);
  }

  Future<void> deletePet(String id) async {
    await client.delete('/pets/$id');
  }

  Future<List<PetModel>> getPetsByProtetor(String protetorId) async {
    final response = await client.get('/pets/protetor/$protetorId');
    final List data = response.data;
    return data.map((json) => PetModel.fromJson(json)).toList();
  }
}
