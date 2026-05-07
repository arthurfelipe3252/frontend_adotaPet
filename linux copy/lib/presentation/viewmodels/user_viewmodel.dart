import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository repository;

  bool isLoading = false;
  List<User> users = [];
  String? error;

  UserViewModel(this.repository);

  Future<void> loadUsers() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      users = await repository.getUsers();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
