import 'package:adota_pet/domain/entities/adoption_request.dart';

abstract class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> getAll();
  Future<AdoptionRequest?> getById(String id);
  Future<AdoptionRequest> create({
    required String petId,
    String? protetorId,
    required String adopterId,
    String? mensagem,
    double? matchScore,
    Map<String, dynamic>? questionario,
  });
  Future<AdoptionRequest> updateStatus(String id, String status);
  Future<void> delete(String id);
}