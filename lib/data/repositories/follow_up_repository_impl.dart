import '../../domain/entities/adoption_follow_up.dart';
import '../../domain/entities/follow_up_update.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../datasources/follow_up_remote_datasource.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpRemoteDatasource remote;

  FollowUpRepositoryImpl(this.remote);

  @override
  Future<List<AdoptionFollowUp>> getFollowUps() async {
    final models = await remote.getFollowUps();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AdoptionFollowUp?> getFollowUpById(String id) async {
    final model = await remote.getFollowUpById(id);
    return model?.toEntity();
  }

  @override
  Future<List<FollowUpUpdate>> getUpdatesByFollowUpId(String followUpId) async {
    final models = await remote.getUpdatesByFollowUpId(followUpId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> sendUpdate(String followUpId, {
    required List<String> fotosPaths,
    String? descricao,
    String? statusSaude,
    String? statusComportamento,
    String? statusAlimentacao,
  }) async {
    await remote.sendUpdate(
      followUpId,
      fotosPaths: fotosPaths,
      descricao: descricao,
      statusSaude: statusSaude,
      statusComportamento: statusComportamento,
      statusAlimentacao: statusAlimentacao,
    );
  }

  @override
  Future<void> respondUpdate(String updateId, {
    required bool aprovado,
    String? comentario,
  }) async {
    await remote.respondUpdate(updateId, aprovado: aprovado, comentario: comentario);
  }

  @override
  Future<void> concludeFollowUp(String followUpId) async {
    await remote.concludeFollowUp(followUpId);
  }
}
