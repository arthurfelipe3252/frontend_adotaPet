import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/auth_session.dart';
import 'package:adota_pet/domain/entities/usuario.dart';
import 'package:adota_pet/domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;

  bool isLoading = false;
  String? error;
  Map<String, String> fieldErrors = {};
  AuthSession? session;
  bool bootstrapDone = false;

  AuthViewModel(this.repository);

  bool get isAuthenticated => session != null;

  Future<void> bootstrap() async {
    if (bootstrapDone) return;
    try {
      session = await repository.tryRestoreSession();
    } catch (_) {
      session = null;
    }
    bootstrapDone = true;
    notifyListeners();
  }

  Future<bool> login(String email, String senha) async {
    isLoading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();

    try {
      final restored = await repository.login(
        email: email.trim(),
        senha: senha,
      );

      if (restored.usuario.tipoUsuario == Usuario.tipoAdotante) {
        await repository.logout();
        session = null;
        _setError(Failure('Esta área é exclusiva para protetores e ONGs.'));
        return false;
      }

      session = restored;
      isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _setError(f);
      return false;
    } catch (_) {
      _setError(Failure('Não foi possível concluir o login.'));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      // Best-effort.
    }
    session = null;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  void clearError() {
    if (error == null && fieldErrors.isEmpty) return;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  void _setError(Failure f) {
    if (f.field != null) {
      fieldErrors = {f.field!: f.message};
      error = null;
    } else {
      fieldErrors = {};
      error = f.message;
    }
    isLoading = false;
    notifyListeners();
  }
}
