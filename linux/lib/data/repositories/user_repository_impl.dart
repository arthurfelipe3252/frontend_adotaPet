import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../../core/errors/failure.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource remote;

  UserRepositoryImpl(this.remote);

  @override
  Future<List<User>> getUsers() async {
    try {
      final models = await remote.getUsers();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Failure("Não foi possível carregar os usuários");
    }
  }

  @override
  Future<User> getUser(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createUser(User user) async {
    throw UnimplementedError();
  }
}
