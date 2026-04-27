import 'package:flutter/foundation.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String email = '';
  bool isLoading = false;
  bool sent = false;
  Map<String, String> fieldErrors = {};

  void setEmail(String value) {
    email = value;
    if (fieldErrors.containsKey('email')) {
      fieldErrors.remove('email');
      notifyListeners();
    }
  }

  Future<void> submit() async {
    fieldErrors = {};
    final trimmed = email.trim();
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) {
      fieldErrors = {'email': 'Informe um email válido.'};
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    isLoading = false;
    sent = true;
    notifyListeners();
  }

  void reset() {
    email = '';
    sent = false;
    isLoading = false;
    fieldErrors = {};
    notifyListeners();
  }
}
