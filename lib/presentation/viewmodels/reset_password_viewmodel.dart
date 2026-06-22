import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/auth_remote_datasource.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final AuthRemoteDatasource _authRemote;

  ResetPasswordViewModel(this._authRemote);

  String novaSenha = '';
  String confirmarSenha = '';
  bool isLoading = false;
  bool done = false;
  String? error;
  Map<String, String> fieldErrors = {};

  void setNovaSenha(String value) {
    novaSenha = value;
    if (fieldErrors.containsKey('novaSenha')) {
      fieldErrors.remove('novaSenha');
      notifyListeners();
    }
  }

  void setConfirmarSenha(String value) {
    confirmarSenha = value;
    if (fieldErrors.containsKey('confirmarSenha')) {
      fieldErrors.remove('confirmarSenha');
      notifyListeners();
    }
  }

  Future<void> submit(String? token) async {
    fieldErrors = {};
    error = null;

    if (token == null || token.isEmpty) {
      error = 'Link inválido ou expirado. Solicite uma nova recuperação.';
      notifyListeners();
      return;
    }

    final errors = <String, String>{};
    if (novaSenha.length < 8) {
      errors['novaSenha'] = 'A senha deve ter pelo menos 8 caracteres.';
    }
    if (confirmarSenha != novaSenha) {
      errors['confirmarSenha'] = 'As senhas não coincidem.';
    }
    if (errors.isNotEmpty) {
      fieldErrors = errors;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _authRemote.resetPassword(token: token, novaSenha: novaSenha);
      done = true;
    } on Failure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Não foi possível redefinir a senha. Tente novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    novaSenha = '';
    confirmarSenha = '';
    isLoading = false;
    done = false;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }
}