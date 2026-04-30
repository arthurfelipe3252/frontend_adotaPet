import 'package:flutter/material.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';

class PetViewModel extends ChangeNotifier {
  final PetRepository repository;

  PetViewModel(this.repository);

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  String? successMessage;

  List<Pet> pets = [];
  Pet? selectedPet;

  String activeFilter = 'Todos';
  String searchQuery = '';

  String _msg(Object e) => e is Failure ? e.message : e.toString();

  List<Pet> get filteredPets {
    var result = pets;
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.nome.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (p.raca?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }
    switch (activeFilter) {
      case 'Disponíveis':
        return result.where((p) => p.status == 'disponivel').toList();
      case 'Em processo':
        return result.where((p) => p.status == 'em_processo').toList();
      case 'Adotados':
        return result.where((p) => p.status == 'adotado').toList();
      default:
        return result;
    }
  }

  void setFilter(String filter) {
    activeFilter = filter;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearMessages() {
    error = null;
    successMessage = null;
  }

  Future<void> loadPets() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      pets = await repository.getPets();
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadPetById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      selectedPet = await repository.getPetById(id);
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createPet(Map<String, dynamic> data) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await repository.createPet(data);
      successMessage = 'Pet cadastrado com sucesso! 🐾';
      isSaving = false;
      notifyListeners();
      // Recarrega a lista em background — sem bloquear o retorno de sucesso.
      // Erros de rede aqui não devem anular o cadastro já realizado.
      loadPets().ignore();
      return true;
    } catch (e) {
      error = _msg(e);
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePet(String id, Map<String, dynamic> data) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await repository.updatePet(id, data);
      successMessage = 'Pet atualizado com sucesso!';
      isSaving = false;
      notifyListeners();
      loadPets().ignore();
      return true;
    } catch (e) {
      error = _msg(e);
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePet(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await repository.deletePet(id);
      pets.removeWhere((p) => p.id == id);
      successMessage = 'Pet removido.';
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = _msg(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
