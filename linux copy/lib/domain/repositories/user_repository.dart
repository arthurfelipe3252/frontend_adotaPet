import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUser(String id);
  Future<void> createUser(User user);
}
