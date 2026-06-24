import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/auth_remote_datasource.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final AuthRemoteDatasource _authRemote;

  ForgotPasswordViewModel(this._authRemote);

  String email = '';
  bool isLoading = false;
  bool sent = false;
  String? error;
  Map<String, String> fieldErrors = {};

  void setEmail(String value) {
    email = value;
    if (fieldErrors.containsKey('email')) {
      fieldErrors.remove('email');
      notifyListeners();
    }
  }

  /// Solicita o link de recuperação de senha via `POST /users/auth/forgot-password`.
  /// O backend sempre responde com sucesso (mesmo se o email não existir, por
  /// design anti-enumeração) — então `sent = true` aqui não confirma que um
  /// e-mail foi de fato recebido, só que a solicitação foi aceita.
  Future<void> submit() async {
    fieldErrors = {};
    error = null;
    final trimmed = email.trim();
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) {
      fieldErrors = {'email': 'Informe um email válido.'};
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _authRemote.forgotPassword(trimmed);
      sent = true;
    } on Failure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Não foi possível enviar o link. Tente novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    email = '';
    sent = false;
    isLoading = false;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }
}