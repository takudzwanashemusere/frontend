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

  // Cache the active hackathon ID across calls within a session.
  static String? _activeHackathonId;

  /// Ensures we have the active hackathon ID cached.
  static Future<String?> _ensureHackathonId() async {
    if (_activeHackathonId != null) return _activeHackathonId;
    final opts = await _authOptions();
    final resp = await _dio.get('/api/hackathons', options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['hackathons'] ?? []) : raw)
            as List? ??
        [];
    if (list.isEmpty) return null;
    _activeHackathonId = (list.first as Map)['id']?.toString();
    return _activeHackathonId;
  }

  // ── Backward-compatible wrappers (used by hackathon_screen.dart) ───────────

  /// Fetch the active hackathon event detail.
  static Future<Map<String, dynamic>> getEvent() async {
    final id = await _ensureHackathonId();
    if (id == null) return {};
    final opts = await _authOptions();
    final resp = await _dio.get('/api/hackathons/$id', options: opts);
    final raw = resp.data;
    final m = Map<String, dynamic>.from(
      raw is Map ? (raw['data'] ?? raw) : {},
    );
    // Normalize: expose `deadline` from `submissions_due_at`
    return {
      ...m,
      'deadline': m['submissions_due_at'] ?? m['deadline'],
    };
  }

  /// Fetch submissions for the active hackathon (displayed as "projects").
  static Future<List<Map<String, dynamic>>> getProjects(
      {String? faculty}) async {
    final id = await _ensureHackathonId();
    if (id == null) return [];
    final opts = await _authOptions();
    final resp =
        await _dio.get('/api/hackathons/$id/submissions', options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['submissions'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final team = m['team'] is Map
          ? Map<String, dynamic>.from(m['team'] as Map)
          : <String, dynamic>{};
      return {
        ...m,
        // Normalize to old field names expected by hackathon_screen.dart
        'id': team['id'] ?? m['team_id'] ?? m['id'],
        'title': m['project_name'] ?? m['title'] ?? '',
        'team': team['name'] ?? m['team_name'] ?? '',
        'description': m['description'] ?? m['desc'] ?? '',
        'votes_count': m['votes_count'] ?? 0,
      };
    }).toList();
  }

  /// Vote for a submission by its team ID.
  static Future<void> voteForProject(dynamic teamId) async {
    final id = await _ensureHackathonId();
    if (id == null) throw Exception('No active hackathon');
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$id/vote',
      data: {'team_id': teamId},
      options: opts,
    );
  }

  /// Save a draft submission for the active hackathon.
  /// [description] must be at least 100 characters.
  /// Optional: [repoUrl], [demoUrl], [videoUrl], [additionalLinks].
  static Future<void> submitProject({
    required String title,
    required String description,
    String? repoUrl,
    String? demoUrl,
    String? videoUrl,
    List<String>? additionalLinks,
    // Legacy params kept for call-site compatibility (ignored by API)
    String? team,
    String? category,
  }) async {
    final id = await _ensureHackathonId();
    if (id == null) throw Exception('No active hackathon');
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$id/submission',
      data: {
        'project_name': title,
        'description': description,
        if (repoUrl != null && repoUrl.isNotEmpty) 'repo_url': repoUrl,
        if (demoUrl != null && demoUrl.isNotEmpty) 'demo_url': demoUrl,
        if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
        if (additionalLinks != null && additionalLinks.isNotEmpty)
          'additional_links': additionalLinks,
      },
      options: opts,
    );
  }

  // ── New API methods ────────────────────────────────────────────────────────

  /// List all hackathons.
  static Future<List<Map<String, dynamic>>> getHackathons() async {
    final opts = await _authOptions();
    final resp = await _dio.get('/api/hackathons', options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['hackathons'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Get hackathon detail by ID.
  static Future<Map<String, dynamic>> getHackathon(
      String hackathonId) async {
    final opts = await _authOptions();
    final resp =
        await _dio.get('/api/hackathons/$hackathonId', options: opts);
    final raw = resp.data;
    return Map<String, dynamic>.from(
        raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Create a team for a hackathon.
  static Future<Map<String, dynamic>> createTeam(
      String hackathonId, String name) async {
    final opts = await _authOptions();
    final resp = await _dio.post(
      '/api/hackathons/$hackathonId/teams',
      data: {'name': name},
      options: opts,
    );
    final raw = resp.data;
    return Map<String, dynamic>.from(
        raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Join a team using an invite code.
  static Future<void> joinTeam(
      String hackathonId, String inviteCode) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/teams/join',
      data: {'invite_code': inviteCode},
      options: opts,
    );
  }

  /// Leave the current team.
  static Future<void> leaveTeam(String hackathonId) async {
    final opts = await _authOptions();
    await _dio.delete(
        '/api/hackathons/$hackathonId/teams/leave',
        options: opts);
  }

  /// Get open teams (accepting members).
  static Future<List<Map<String, dynamic>>> getOpenTeams(
      String hackathonId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
        '/api/hackathons/$hackathonId/teams/open',
        options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['teams'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Finalise (lock) the team's submission.
  static Future<void> finaliseSubmission(String hackathonId) async {
    final opts = await _authOptions();
    await _dio.post(
        '/api/hackathons/$hackathonId/submission/finalise',
        options: opts);
  }

  /// Get voting status for the current user.
  static Future<Map<String, dynamic>> getVoteStatus(
      String hackathonId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
        '/api/hackathons/$hackathonId/vote/status',
        options: opts);
    final raw = resp.data;
    return Map<String, dynamic>.from(
        raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Get the leaderboard.
  static Future<List<Map<String, dynamic>>> getLeaderboard(
      String hackathonId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
        '/api/hackathons/$hackathonId/leaderboard',
        options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['leaderboard'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Get discussion comments.
  static Future<List<Map<String, dynamic>>> getDiscussion(
      String hackathonId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
        '/api/hackathons/$hackathonId/discussion',
        options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['comments'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Post a discussion comment.
  static Future<void> postComment(String hackathonId, String body) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/discussion',
      data: {'body': body},
      options: opts,
    );
  }

  /// Reply to a discussion comment.
  static Future<void> replyToComment(
      String hackathonId, String commentId, String body) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/discussion/$commentId/reply',
      data: {'body': body},
      options: opts,
    );
  }

  /// Like a discussion comment.
  static Future<void> likeComment(String commentId) async {
    final opts = await _authOptions();
    await _dio.post(
        '/api/hackathon-comments/$commentId/like',
        options: opts);
  }

  /// Delete a discussion comment.
  static Future<void> deleteComment(String commentId) async {
    final opts = await _authOptions();
    await _dio.delete(
        '/api/hackathon-comments/$commentId',
        options: opts);
  }

  /// Get all replies for a discussion comment.
  static Future<List<Map<String, dynamic>>> getCommentReplies(
      String commentId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
        '/api/hackathon-comments/$commentId/replies',
        options: opts);
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['replies'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Mentor ────────────────────────────────────────────────────────────────

  /// Request a mentor for your team.
  /// [mentorId] is the integer ID of the desired mentor.
  static Future<void> requestMentor(
      String hackathonId, int mentorId) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/mentor/request',
      data: {'mentor_id': mentorId},
      options: opts,
    );
  }

  /// Accept a mentor request from a team (mentor action).
  static Future<void> acceptMentorRequest(
      String hackathonId, String teamId) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/mentor/accept/$teamId',
      options: opts,
    );
  }

  /// Send a message in the mentor chat for a team.
  static Future<void> sendMentorMessage(
      String hackathonId, String teamId, String body) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/hackathons/$hackathonId/mentor/chat/$teamId',
      data: {'body': body},
      options: opts,
    );
  }

  /// Fetch mentor chat history for a team.
  static Future<List<Map<String, dynamic>>> getMentorChat(
      String hackathonId, String teamId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
      '/api/hackathons/$hackathonId/mentor/chat/$teamId',
      options: opts,
    );
    final raw = resp.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['messages'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
