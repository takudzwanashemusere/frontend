import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'auth_service.dart';

class HackathonService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kLaravelUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static Future<Options> _authOptions() async {
    final token = await AuthService.getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
  }

  /// Fetch the active hackathon event (title, deadline, description).
  static Future<Map<String, dynamic>> getEvent() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/hackathon', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Fetch projects, optionally filtered by faculty.
  static Future<List<Map<String, dynamic>>> getProjects({String? faculty}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/hackathon/projects',
      queryParameters: {
        if (faculty != null && faculty.isNotEmpty) 'faculty': faculty,
      },
      options: opts,
    );
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['projects'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Submit a new project to the hackathon.
  static Future<void> submitProject({
    required String title,
    required String team,
    required String category,
    required String description,
  }) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathon/projects',
      data: {
        'title': title,
        'team': team,
        'category': category,
        'description': description,
      },
      options: opts,
    );
  }

  /// Cast a vote for a project by its id.
  static Future<void> voteForProject(dynamic projectId) async {
    final opts = await _authOptions();
    await _dio.post('/api/hackathon/projects/$projectId/vote', options: opts);
  }
}
