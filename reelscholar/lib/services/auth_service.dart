import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'user_email';
  static const _keyName = 'user_name';
  static const _keyIsLoggedIn = 'is_logged_in';

  // Save session after login
  static Future<void> saveSession({
    required String email,
    required String name,
    required String token,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyName, value: name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get saved user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  // Get saved user name
  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyName);
  }

  // Get auth token (for API calls)
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Clear session on logout
  static Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}