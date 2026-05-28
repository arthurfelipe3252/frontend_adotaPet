// ignore_for_file: use_null_aware_elements

import 'package:adota_pet/data/datasources/adoption_request_remote_datasource.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/repositories/adoption_request_repository.dart';

class AdoptionRequestRepositoryImpl implements AdoptionRequestRepository {
  final AdoptionRequestRemoteDatasource datasource;

  AdoptionRequestRepositoryImpl(this.datasource);

  @override
  Future<List<AdoptionRequest>> getAll() => datasource.getAll();

  @override
  Future<AdoptionRequest?> getById(String id) => datasource.getById(id);

  @override
  Future<AdoptionRequest> create({
    required String petId,
    String? protetorId,
    required String adopterId,
    String? mensagem,
    double? matchScore,
    Map<String, dynamic>? questionario,
  }) {
    final scoreInt = matchScore != null ? matchScore.round() : null;

    return datasource.create({
      'petId': petId,
      if (protetorId != null) 'protetorId': protetorId,
      'adopterId': adopterId,
      if (mensagem != null && mensagem.isNotEmpty) 'mensagem': mensagem,
      if (scoreInt != null) 'matchScore': scoreInt,
      if (questionario != null) 'questionario': questionario,
    });
  }

  @override
  Future<AdoptionRequest> updateStatus(String id, String status) =>
      datasource.updateStatus(id, status);

  @override
  Future<void> delete(String id) => datasource.delete(id);
}