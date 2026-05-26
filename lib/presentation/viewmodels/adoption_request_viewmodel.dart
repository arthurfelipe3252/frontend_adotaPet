import 'package:flutter/foundation.dart';
import 'package:adota_pet/domain/entities/adoption_request.dart';
import 'package:adota_pet/domain/repositories/adoption_request_repository.dart';

class AdoptionRequestViewmodel extends ChangeNotifier {
  final AdoptionRequestRepository repository;

  AdoptionRequestViewmodel(this.repository);

  bool isLoading = false;
  List<AdoptionRequest> requests = [];
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      requests = await repository.getAll();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
  Future<void> create({
    required String petId,
    required String adopterId,
    String? notes,
    double? matchScore,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final newRequest = await repository.create(
        petId: petId,
        adopterId: adopterId,
        notes: notes,
        matchScore: matchScore,
      );
      requests= [...requests, newRequest];
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final updatedRequest = await repository.updateStatus(id, status);
      requests = requests.map((r) => r.id == id ? updatedRequest : r).toList();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await repository.delete(id);
      requests = requests.where((r) => r.id != id).toList();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}