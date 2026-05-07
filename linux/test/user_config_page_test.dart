import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adota_pet/presentation/pages/user_config_page.dart';
import 'package:adota_pet/presentation/viewmodels/user_viewmodel.dart';
import 'package:adota_pet/domain/entities/user.dart';
import 'package:adota_pet/domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  @override
  Future<List<User>> getUsers() async {
    return [
      const User(
        id: '1',
        name: 'Mock NGO',
        email: 'mock@ngo.com',
        type: UserType.ngo,
      ),
    ];
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

void main() {
  testWidgets('UserConfigPage displays a list of users', (
    WidgetTester tester,
  ) async {
    final userRepository = MockUserRepository();
    final userViewModel = UserViewModel(userRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserViewModel>.value(value: userViewModel),
          ],
          child: const UserConfigPage(),
        ),
      ),
    );

    // Initial state is loading (since loadUsers is called in initState, it might be running or finished)
    // Wait for the Future to complete and the widget to rebuild.
    await tester.pumpAndSettle();

    expect(find.text('Mock NGO'), findsOneWidget);
    expect(find.text('ONG'), findsOneWidget);
  });
}
