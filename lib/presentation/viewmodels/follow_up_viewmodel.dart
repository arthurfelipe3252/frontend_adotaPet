import 'package:flutter/material.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/adoption_follow_up.dart';
import '../../domain/entities/follow_up_update.dart';
import '../../domain/repositories/follow_up_repository.dart';

class FollowUpViewModel extends ChangeNotifier {
  final FollowUpRepository repository;

  FollowUpViewModel(this.repository);

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  String? successMessage;

  List<AdoptionFollowUp> followUps = [];
  AdoptionFollowUp? selectedFollowUp;
  List<FollowUpUpdate> updates = [];

  String _msg(Object e) => e is Failure ? e.message : e.toString();

  void clearMessages() { error = null; successMessage = null; }

  Future<void> loadFollowUps() async {
    isLoading = true; error = null; notifyListeners();
    try {
      followUps = await repository.getFollowUps();
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false; notifyListeners();
  }

  Future<void> loadFollowUpDetails(String id) async {
    isLoading = true; error = null; notifyListeners();
    try {
      selectedFollowUp = await repository.getFollowUpById(id);
      updates = await repository.getUpdatesByFollowUpId(id);
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false; notifyListeners();
  }

  Future<bool> sendUpdate({
    required String followUpId,
    required List<String> fotosPaths,
    String? descricao,
    String? statusSaude,
    String? statusComportamento,
    String? statusAlimentacao,
  }) async {
    isSaving = true; error = null; notifyListeners();
    try {
      await repository.sendUpdate(
        followUpId,
        fotosPaths: fotosPaths,
        descricao: descricao,
        statusSaude: statusSaude,
        statusComportamento: statusComportamento,
        statusAlimentacao: statusAlimentacao,
      );
      successMessage = 'Atualização enviada com sucesso! ❤️';
      isSaving = false;
      await loadFollowUpDetails(followUpId);
      return true;
    } catch (e) {
      error = _msg(e);
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondUpdate(String updateId, String followUpId, {
    required bool aprovado,
    String? comentario,
  }) async {
    isSaving = true; error = null; notifyListeners();
    try {
      await repository.respondUpdate(updateId, aprovado: aprovado, comentario: comentario);
      successMessage = 'Resposta enviada.';
      isSaving = false;
      await loadFollowUpDetails(followUpId);
      return true;
    } catch (e) {
      error = _msg(e);
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> concludeFollowUp(String followUpId) async {
    isLoading = true; error = null; notifyListeners();
    try {
      await repository.concludeFollowUp(followUpId);
      successMessage = 'Acompanhamento finalizado com sucesso!';
      await loadFollowUpDetails(followUpId);
      return true;
    } catch (e) {
      error = _msg(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
