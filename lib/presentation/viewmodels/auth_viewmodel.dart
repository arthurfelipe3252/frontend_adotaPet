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

  /// Faz login validando opcionalmente o tipo do usuário.
  ///
  /// Se `tiposPermitidos` for informado e o tipo do usuário autenticado não
  /// estiver no conjunto, a sessão é encerrada e o login retorna `false` com
  /// `mensagemTipoInvalido` exibida em `error`. Útil pra restringir o login
  /// por plataforma (web só ONG/Protetor, mobile só Adotante).
  Future<bool> login(
    String email,
    String senha, {
    Set<String>? tiposPermitidos,
    String mensagemTipoInvalido =
        'Seu tipo de usuário não tem acesso a esta plataforma.',
  }) async {
    isLoading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();

    try {
      final restored = await repository.login(
        email: email.trim(),
        senha: senha,
      );

      if (tiposPermitidos != null &&
          !tiposPermitidos.contains(restored.usuario.tipoUsuario)) {
        await repository.logout();
        session = null;
        _setError(Failure(mensagemTipoInvalido));
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

  Future<void> logoutAll() async {
    try {
      await repository.logoutAll();
    } catch (_) {
      // Best-effort.
    }
    session = null;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  void updateUsuario(Usuario usuario) {
    final current = session;
    if (current == null) return;
    session = AuthSession(
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      expiresAt: current.expiresAt,
      usuario: usuario,
    );
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
