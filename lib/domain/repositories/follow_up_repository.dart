import '../entities/adoption_follow_up.dart';
import '../entities/follow_up_update.dart';

abstract class FollowUpRepository {
  Future<List<AdoptionFollowUp>> getFollowUps();
  Future<AdoptionFollowUp?> getFollowUpById(String id);
  Future<List<FollowUpUpdate>> getUpdatesByFollowUpId(String followUpId);
  
  Future<void> sendUpdate(String followUpId, {
    required List<String> fotosPaths,
    String? descricao,
    String? statusSaude,
    String? statusComportamento,
    String? statusAlimentacao,
  });

  Future<void> respondUpdate(String updateId, {
    required bool aprovado,
    String? comentario,
  });

  Future<void> concludeFollowUp(String followUpId);
}
