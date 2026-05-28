// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/foundation.dart';
import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/repositories/adoption_request_repository.dart';

class AdoptionRequestViewmodel extends ChangeNotifier {
  final AdoptionRequestRepository repository;

  AdoptionRequestViewmodel(this.repository);

  bool isLoading = false;
  bool isSending = false;
  List<AdoptionRequest> requests = [];
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      requests = await repository.getAll();
      error = null;
    } catch (e) {
      error = _friendly(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createFromPetDetail({
    required String petId,
    required String adopterId,
    String? protetorId,
    String? mensagem,
    Map<String, dynamic>? questionario,
  }) async {
    isSending = true;
    error = null;
    notifyListeners();

    final matchScore = questionario != null ? _calcularMatchScore(questionario) : null;

    try {
      final nova = await repository.create(
        petId: petId,
        protetorId: protetorId,
        adopterId: adopterId,
        mensagem: mensagem,
        matchScore: matchScore,
        questionario: questionario,
      );

      requests = [...requests, nova];
      isSending = false;
      notifyListeners();

      AppNotifier.instance.success('Solicitação enviada com sucesso! 🐾');
      _reloadSilently();

      return true;
    } catch (e) {
      error = _friendly(e);
      AppNotifier.instance.error(_friendly(e));
      isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      final updated = await repository.updateStatus(id, status);
      requests = requests.map((r) => r.id == id ? updated : r).toList();
      AppNotifier.instance.success('Solicitação ${_statusLabel(status)}.');
    } catch (e) {
      error = _friendly(e);
      AppNotifier.instance.error('Erro ao atualizar status.');
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final snapshot = List<AdoptionRequest>.from(requests);
    requests = requests.where((r) => r.id != id).toList();
    notifyListeners();

    try {
      await repository.delete(id);
      AppNotifier.instance.success('Solicitação removida.');
    } catch (e) {
      requests = snapshot;
      error = _friendly(e);
      AppNotifier.instance.error('Erro ao remover solicitação.');
      notifyListeners();
    }
  }

  Future<void> create({
    required String petId,
    required String adopterId,
    String? protetorId,
    String? notes,
    double? matchScore,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final r = await repository.create(
        petId: petId,
        protetorId: protetorId,
        adopterId: adopterId,
        mensagem: notes,
        matchScore: matchScore,
      );
      requests = [...requests, r];
    } catch (e) {
      error = _friendly(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadSilently() async {
    try {
      requests = await repository.getAll();
      notifyListeners();
    } catch (_) {}
  }

  double _calcularMatchScore(Map<String, dynamic> q) {
    double score = 50;
    final moradia = q['tipoMoradia'] as String?;
    if (moradia == 'casa_com_quintal') score += 20;
    if (moradia == 'casa_sem_quintal') score += 10;
    final horas = q['horasDisponiveisDia'];
    if (horas != null) {
      final h = (horas as num).toInt();
      if (h >= 6) score += 15;
      else if (h >= 3) score += 8;
    }
    if (q['temExperiencia'] == true) score += 15;
    if (q['temCriancas'] == false) score += 5;
    if (q['temOutrosPets'] == false) score += 5;
    return score.clamp(0, 100);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_analysis': return 'em análise';
      case 'approved': return 'aprovada';
      case 'rejected': return 'rejeitada';
      default: return status;
    }
  }

  String _friendly(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Failure(') && raw.endsWith(')')) {
      return raw.substring(8, raw.length - 1);
    }
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return raw;
  }
}