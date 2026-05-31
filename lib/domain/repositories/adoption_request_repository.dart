import 'package:adota_pet/domain/entities/adoption_request.dart';

abstract class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> getAll();
  Future<AdoptionRequest?> getById(String id);
  /// Cria uma solicitação de adoção. O adotante (autor) é derivado do JWT e o
  /// protetor é derivado do pet — por isso NÃO recebem `adopterId`/`protetorId`.
  Future<AdoptionRequest> create({
    required String petId,
    String? mensagem,
    double? matchScore,
    Map<String, dynamic>? questionario,
  });
  Future<AdoptionRequest> updateStatus(String id, String status);
  Future<void> delete(String id);
}