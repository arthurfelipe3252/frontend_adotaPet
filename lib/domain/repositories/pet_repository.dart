import '../entities/pet.dart';

abstract class PetRepository {
  Future<List<Pet>> getPets({String? especie, String? porte, String? status});
  Future<Pet> getPetById(String id);
  Future<Pet> createPet(Map<String, dynamic> data);
  Future<Pet> updatePet(String id, Map<String, dynamic> data);
  Future<void> deletePet(String id);
  Future<List<Pet>> getPetsByProtetor(String protetorId);
}
