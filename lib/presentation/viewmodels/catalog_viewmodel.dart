import 'package:flutter/material.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';

class CatalogViewModel extends ChangeNotifier {
  final PetRepository repository;

  CatalogViewModel(this.repository);

  // ── Estado ────────────────────────────────────────────────────────────────

  bool isLoading = false;
  String? error;
  List<Pet> _allPets = [];

  String searchQuery = '';
  bool isGridView = true;
  bool showFilters = false;

  // filtros múltiplos por categoria
  final Map<String, Set<String>> activeFilters = {
    'especie': {},
    'porte': {},
    'sexo': {},
    'saude': {},
  };

  String _msg(Object e) => e is Failure ? e.message : e.toString();

  // ── Computed ──────────────────────────────────────────────────────────────

  int get totalFiltrosAtivos =>
      activeFilters.values.fold(0, (sum, set) => sum + set.length);

  List<Pet> get filteredPets {
    var result = _allPets;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) =>
        p.nome.toLowerCase().contains(q) ||
        (p.raca?.toLowerCase().contains(q) ?? false) ||
        p.especieLabel.toLowerCase().contains(q),
      ).toList();
    }

    if (activeFilters['especie']!.isNotEmpty) {
      result = result.where((p) => activeFilters['especie']!.contains(p.especie)).toList();
    }
    if (activeFilters['porte']!.isNotEmpty) {
      result = result.where((p) => activeFilters['porte']!.contains(p.porte)).toList();
    }
    if (activeFilters['sexo']!.isNotEmpty) {
      result = result.where((p) => activeFilters['sexo']!.contains(p.sexo)).toList();
    }
    if (activeFilters['saude']!.isNotEmpty) {
      if (activeFilters['saude']!.contains('vacinado')) {
        result = result.where((p) => p.vacinado).toList();
      }
      if (activeFilters['saude']!.contains('castrado')) {
        result = result.where((p) => p.castrado).toList();
      }
    }

    // só disponíveis no catálogo público
    return result.where((p) => p.status == 'disponivel').toList();
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void toggleView() {
    isGridView = !isGridView;
    notifyListeners();
  }

  void toggleFiltersPanel() {
    showFilters = !showFilters;
    notifyListeners();
  }

  void toggleFilter(String category, String value) {
    final set = activeFilters[category]!;
    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }
    notifyListeners();
  }

  void clearFilters() {
    for (final set in activeFilters.values) {
      set.clear();
    }
    notifyListeners();
  }

  /// Carrega todos os pets. Com a guarda, abas que compartilham este viewmodel
  /// (catálogo + home do adotante, ambas vivas no IndexedStack) não baixam o
  /// `GET /pets` em dobro. Use `force: true` para um refresh explícito.
  Future<void> loadPets({bool force = false}) async {
    if (isLoading) return;
    if (!force && _allPets.isNotEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _allPets = await repository.getPets();
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Pet? getPetById(String id) {
    try {
      return _allPets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
