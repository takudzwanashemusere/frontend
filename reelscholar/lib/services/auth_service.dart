import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIX: Token is now saved in BOTH flutter_secure_storage AND SharedPreferences.
//
// Why: On some Android devices, flutter_secure_storage fails to read back the
// token after saving (keystore/encryptedSharedPreferences issues), causing
// AuthService.getToken() to return null even after a successful login.
// This makes every API call send "Bearer null" → 401 Unauthenticated.
//
// Solution: getToken() tries secure storage first, falls back to SharedPrefs.
// saveSession() writes the token to both stores so the fallback is always fresh.
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const _keyToken           = 'auth_token';
  static const _keyTokenFallback   = 'auth_token_fallback'; // SharedPrefs fallback
  static const _keyMessagingToken  = 'messaging_token';
  static const _keyEmail           = 'user_email';
  static const _keyName            = 'user_name';
  static const _keyUserId          = 'user_id';
  static const _keyUsername        = 'user_username';
  static const _keyIsLoggedIn      = 'is_logged_in';
  static const _keyDepartment      = 'user_department';
  static const _keyDegreeProgram   = 'user_degree_program';
  static const _keySemester        = 'user_semester';

  /// Save session after login / register.
  /// Token is written to both secure storage and SharedPreferences.
  static Future<void> saveSession({
    required String email,
    required String name,
    required String token,
    String? userId,
    String? username,
  }) async {
    // Write to secure storage
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyName, value: name);
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: _keyUserId, value: userId);
    }
    if (username != null) {
      await _storage.write(key: _keyUsername, value: username);
    }

    // Also write token + basic info to SharedPreferences as fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTokenFallback, token);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_keyUserId, userId);
    }
    if (username != null) {
      await prefs.setString(_keyUsername, username);
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get auth token — tries secure storage first, falls back to SharedPrefs.
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _keyToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {
      // Secure storage failed — fall through to SharedPrefs
    }
    // Fallback: read from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final fallback = prefs.getString(_keyTokenFallback);
    return (fallback != null && fallback.isNotEmpty) ? fallback : null;
  }

  /// Save selected department
  static Future<void> saveDepartment(String department) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDepartment, department);
  }

  /// Get saved department
  static Future<String?> getDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDepartment);
  }

  /// Save degree programme
  static Future<void> saveDegreeProgram(String program) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDegreeProgram, program);
  }

  /// Get saved degree programme
  static Future<String?> getDegreeProgram() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDegreeProgram);
  }

  /// Check if department has been selected
  static Future<bool> hasDepartment() async {
    final dept = await getDepartment();
    return dept != null && dept.isNotEmpty;
  }

  /// Save current semester (1–8)
  static Future<void> saveSemester(int semester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySemester, semester);
  }

  /// Get current semester (defaults to 1)
  static Future<int> getSemester() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySemester) ?? 1;
  }

  /// Get saved user email — tries secure storage first, falls back
  static Future<String?> getUserEmail() async {
    try {
      final val = await _storage.read(key: _keyEmail);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Get saved user name — tries secure storage first, falls back
  static Future<String?> getUserName() async {
    try {
      final val = await _storage.read(key: _keyName);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  /// Save messaging API JWT
  static Future<void> saveMessagingToken(String token) async {
    await _storage.write(key: _keyMessagingToken, value: token);
  }

  /// Get messaging API JWT
  static Future<String?> getMessagingToken() async {
    try {
      return await _storage.read(key: _keyMessagingToken);
    } catch (_) {
      return null;
    }
  }

  /// Get saved user id — tries secure storage first, falls back
  static Future<String?> getUserId() async {
    try {
      final val = await _storage.read(key: _keyUserId);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Get saved username — tries secure storage first, falls back
  static Future<String?> getUsername() async {
    try {
      final val = await _storage.read(key: _keyUsername);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // ── Profile extras ──────────────────────────────────────────────────────────

  static const _keyBio              = 'user_bio';
  static const _keyProfileImagePath = 'profile_image_path';

  static Future<void> saveBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBio, bio);
  }

  static Future<String?> getBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBio);
  }

  static Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImagePath, path);
  }

  static Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileImagePath);
  }

  static Future<void> clearProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileImagePath);
  }

  /// Clear all session data on logout
  static Future<void> logout() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}