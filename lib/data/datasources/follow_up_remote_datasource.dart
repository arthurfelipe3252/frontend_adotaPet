import 'package:dio/dio.dart';
import '../../core/network/http_client.dart';
import '../models/adoption_follow_up_model.dart';
import '../models/follow_up_update_model.dart';

class FollowUpRemoteDatasource {
  final HttpClient client;

  FollowUpRemoteDatasource(this.client);

  Future<List<AdoptionFollowUpModel>> getFollowUps() async {
    final response = await client.get('/follow-ups');
    final List data = response.data;
    return data.map((json) => AdoptionFollowUpModel.fromJson(json)).toList();
  }

  Future<AdoptionFollowUpModel?> getFollowUpById(String id) async {
    final response = await client.get('/follow-ups/$id');
    return AdoptionFollowUpModel.fromJson(response.data);
  }

  Future<List<FollowUpUpdateModel>> getUpdatesByFollowUpId(
    String followUpId,
  ) async {
    final response = await client.get('/follow-ups/$followUpId/updates');
    final List data = response.data;
    return data.map((json) => FollowUpUpdateModel.fromJson(json)).toList();
  }

  Future<void> sendUpdate(
    String followUpId, {
    required List<String> fotosPaths,
    String? descricao,
    String? statusSaude,
    String? statusComportamento,
    String? statusAlimentacao,
  }) async {
    final formData = FormData.fromMap({
      'descricao': descricao,
      'statusSaude': statusSaude,
      'statusComportamento': statusComportamento,
      'statusAlimentacao': statusAlimentacao,
    });

    for (var path in fotosPaths) {
      formData.files.add(MapEntry('fotos', await MultipartFile.fromFile(path)));
    }

    await client.post('/follow-ups/$followUpId/updates', data: formData);
  }

  Future<void> respondUpdate(
    String updateId, {
    required bool aprovado,
    String? comentario,
  }) async {
    await client.patch(
      '/follow-ups/updates/$updateId',
      data: {'aprovado': aprovado, 'comentario': comentario},
    );
  }

  Future<void> concludeFollowUp(String followUpId) async {
    await client.post('/follow-ups/$followUpId/conclude');
  }
}
