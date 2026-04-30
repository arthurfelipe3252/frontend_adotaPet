import '../models/pet_model.dart';

class PetCacheDatasource {
  List<PetModel>? _cache;

  void save(List<PetModel> pets) {
    _cache = pets;
  }

  List<PetModel>? get() {
    return _cache;
  }

  void clear() {
    _cache = null;
  }
}
