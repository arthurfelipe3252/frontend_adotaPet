import '../../core/network/http_client.dart';
import '../models/user_model.dart';
import '../../core/errors/failure.dart';

class UserRemoteDatasource {
  final HttpClient client;

  UserRemoteDatasource(this.client);

  Future<List<UserModel>> getUsers() async {
    try {
      // Mocking the data for testing since backend isn't available
      await Future.delayed(
        const Duration(seconds: 1),
      ); // simulate network delay
      return [
        UserModel(
          id: '1',
          name: 'ONG Salva Pets',
          email: 'contato@salvapets.org',
          type: 'ngo',
        ),
        UserModel(
          id: '2',
          name: 'João Doador',
          email: 'joao@exemplo.com',
          type: 'donor',
        ),
        UserModel(
          id: '3',
          name: 'ONG Vida Animal',
          email: 'vida@animal.org',
          type: 'ngo',
        ),
      ];
    } catch (e) {
      throw Failure("Failed to load users from API");
    }
  }
}
