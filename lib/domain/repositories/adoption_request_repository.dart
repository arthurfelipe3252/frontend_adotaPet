import 'package:adota_pet/domain/entities/adoption_request.dart';

abstract class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> getAll();
  Future<AdoptionRequest?> getById(String id);
  Future<AdoptionRequest> create({
    required String petId,
    required String adopterId,
    String? notes,
    double? matchScore,
  });
  Future<AdoptionRequest> updateStatus(String id, String status);
  Future<void> delete(String id);
}