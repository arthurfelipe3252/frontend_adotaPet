import 'package:dio/dio.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_cache_datasource.dart';
import '../datasources/pet_remote_datasource.dart';

class PetRepositoryImpl implements PetRepository {
  final PetRemoteDatasource remote;
  final PetCacheDatasource cache;

  PetRepositoryImpl(this.remote, this.cache);

  // ── Helper: extrai mensagem legível do erro ────────────────────────────────

  String _mensagemDoErro(Object e, String fallback) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Tempo de conexão esgotado. Verifique sua internet.';
        case DioExceptionType.connectionError:
          return 'Sem conexão com o servidor. Verifique se o backend está rodando.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          final body = e.response?.data;
          if (status == 400) {
            // Tenta extrair mensagem de validação do NestJS
            if (body is Map && body['message'] != null) {
              final msg = body['message'];
              if (msg is List) return msg.join('\n');
              return msg.toString();
            }
            return 'Dados inválidos. Verifique os campos preenchidos.';
          }
          if (status == 401) return 'Sessão expirada. Faça login novamente.';
          if (status == 403) return 'Você não tem permissão para realizar esta ação.';
          if (status == 404) return 'Registro não encontrado.';
          if (status == 409) return 'Conflito: este registro já existe.';
          if (status != null && status >= 500) return 'Erro interno do servidor. Tente novamente mais tarde.';
          return fallback;
        default:
          return fallback;
      }
    }
    if (e is Failure) return e.message;
    return fallback;
  }

  @override
  Future<List<Pet>> getPets({String? especie, String? porte, String? status}) async {
    try {
      final models = await remote.getPets(especie: especie, porte: porte, status: status);
      cache.save(models);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      final cached = cache.get();
      if (cached != null) return cached.map((m) => m.toEntity()).toList();
      throw Failure(_mensagemDoErro(e, 'Não foi possível carregar os pets.'));
    }
  }

  @override
  Future<Pet> getPetById(String id) async {
    try {
      final model = await remote.getPetById(id);
      return model.toEntity();
    } catch (e) {
      throw Failure(_mensagemDoErro(e, 'Pet não encontrado.'));
    }
  }

  @override
  Future<Pet> createPet(Map<String, dynamic> data) async {
    try {
      final model = await remote.createPet(data);
      cache.clear();
      return model.toEntity();
    } catch (e) {
      throw Failure(_mensagemDoErro(e, 'Não foi possível cadastrar o pet.'));
    }
  }

  @override
  Future<Pet> updatePet(String id, Map<String, dynamic> data) async {
    try {
      final model = await remote.updatePet(id, data);
      cache.clear();
      return model.toEntity();
    } catch (e) {
      throw Failure(_mensagemDoErro(e, 'Não foi possível atualizar o pet.'));
    }
  }

  @override
  Future<void> deletePet(String id) async {
    try {
      await remote.deletePet(id);
      cache.clear();
    } catch (e) {
      throw Failure(_mensagemDoErro(e, 'Não foi possível remover o pet.'));
    }
  }

  @override
  Future<List<Pet>> getPetsByProtetor(String protetorId) async {
    try {
      final models = await remote.getPetsByProtetor(protetorId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Failure(_mensagemDoErro(e, 'Não foi possível carregar os pets da organização.'));
    }
  }
}

