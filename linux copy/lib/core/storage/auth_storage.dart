import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _refreshKey = 'auth_refresh_token';

  final SharedPreferences _prefs;

  AuthStorage(this._prefs);

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshKey, token);
  }

  String? readRefreshToken() {
    return _prefs.getString(_refreshKey);
  }

  Future<void> clear() async {
    await _prefs.remove(_refreshKey);
  }
}
