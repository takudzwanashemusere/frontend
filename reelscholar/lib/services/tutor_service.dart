import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'auth_service.dart';

class TutorService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kLaravelUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<Options> _authOptions() async {
    final token = await AuthService.getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
  }

  /// GET /api/tutor/modules
  /// Returns modules for the student's programme grouped by year/semester,
  /// with progress for each module.
  static Future<dynamic> getModules() async {
    final opts = await _authOptions();
    final res = await _dio.get('/api/tutor/modules', options: opts);
    final raw = res.data;
    return (raw is Map) ? raw['data'] : raw;
  }

  /// POST /api/tutor/modules/{module}/start
  /// Start or resume a tutor conversation for a module.
  static Future<Map<String, dynamic>> startSession(String moduleId) async {
    final opts = await _authOptions();
    final res = await _dio.post(
      '/api/tutor/modules/$moduleId/start',
      options: opts,
    );
    final raw = res.data;
    return Map<String, dynamic>.from(
      (raw is Map && raw.containsKey('data')) ? raw['data'] : raw,
    );
  }

  /// POST /api/tutor/modules/{module}/chat
  /// Send a message in an active tutor session.
  static Future<Map<String, dynamic>> chat(
      String moduleId, String message) async {
    final opts = await _authOptions();
    final res = await _dio.post(
      '/api/tutor/modules/$moduleId/chat',
      data: {'message': message},
      options: opts,
    );
    final raw = res.data;
    return Map<String, dynamic>.from(
      (raw is Map && raw.containsKey('data')) ? raw['data'] : raw,
    );
  }

  /// GET /api/tutor/modules/{module}/quiz
  /// Get the latest quiz for a module.
  static Future<Map<String, dynamic>> getQuiz(String moduleId) async {
    final opts = await _authOptions();
    final res = await _dio.get(
      '/api/tutor/modules/$moduleId/quiz',
      options: opts,
    );
    final raw = res.data;
    return Map<String, dynamic>.from(
      (raw is Map && raw.containsKey('data')) ? raw['data'] : raw,
    );
  }

  /// GET /api/tutor/modules/{module}/history
  /// Get conversation history for a module.
  static Future<List<dynamic>> getHistory(String moduleId) async {
    final opts = await _authOptions();
    final res = await _dio.get(
      '/api/tutor/modules/$moduleId/history',
      options: opts,
    );
    final raw = res.data;
    final data = (raw is Map) ? raw['data'] : raw;
    if (data is Map && data['messages'] != null) {
      final msgs = data['messages'];
      if (msgs is List) return msgs;
      if (msgs is String) return [];
    }
    return [];
  }

  /// POST /api/tutor/modules/{module}/reset
  /// Reset a module's tutor session (start fresh).
  static Future<void> resetSession(String moduleId) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/tutor/modules/$moduleId/reset',
      options: opts,
    );
  }
}
