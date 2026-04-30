import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'api_constants.dart';

class VideoService {
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

  static (int, int) _schoolColors(String school) {
    final s = school.toLowerCase();
    if (s.contains('engineering')) return (0xFF1A1040, 0xFF6C63FF);
    if (s.contains('agriculture')) return (0xFF0D2818, 0xFF2ECC71);
    if (s.contains('business') || s.contains('entrepreneurship')) return (0xFF1A0A00, 0xFFFF6B35);
    if (s.contains('health')) return (0xFF1A0020, 0xFFE040FB);
    if (s.contains('wildlife') || s.contains('environmental')) return (0xFF001A2A, 0xFF00BCD4);
    if (s.contains('hospitality') || s.contains('tourism')) return (0xFF1A0D00, 0xFFFFAB40);
    if (s.contains('natural') || s.contains('mathematics')) return (0xFF001A1A, 0xFF00BFA5);
    return (0xFF1A1A2E, 0xFF6C63FF);
  }

  static String formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count?.toString() ?? '') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static Map<String, dynamic> normalizeVideo(Map<String, dynamic> v) {
    final uploader = (v['uploader'] is Map)
        ? v['uploader'] as Map<String, dynamic>
        : (v['user'] is Map)
            ? v['user'] as Map<String, dynamic>
            : <String, dynamic>{};
    final school = uploader['faculty']?.toString() ??
        v['school']?.toString() ??
        v['school_name']?.toString() ??
        v['faculty']?.toString() ??
        '';
    final colors = _schoolColors(school);
    bool isTruthy(dynamic val) =>
        val == true || val == 1 || val?.toString() == 'true' || val?.toString() == '1';
    return {
      'id': v['id'],
      'userId': uploader['uid'] ?? uploader['id'] ?? v['user_id'] ?? v['author_id'],
      'username': '@${uploader['username'] ?? v['username'] ?? 'user'}',
      'name': uploader['name'] ?? uploader['full_name'] ?? v['author_name'] ?? 'Unknown',
      'school': school,
      'subject': v['subject']?.toString() ?? v['module']?.toString() ?? '',
      'title': v['caption']?.toString() ?? v['title']?.toString() ?? '',
      'likes': formatCount(v['like_count'] ?? v['likes_count'] ?? v['likes'] ?? 0),
      'comments': formatCount(v['comment_count'] ?? v['comments_count'] ?? v['comments'] ?? 0),
      'shares': formatCount(v['share_count'] ?? v['shares_count'] ?? v['shares'] ?? 0),
      'likesCount': int.tryParse((v['like_count'] ?? v['likes_count'] ?? v['likes'] ?? 0).toString()) ?? 0,
      'isLiked': isTruthy(v['is_liked']),
      'isBookmarked': isTruthy(v['is_bookmarked']),
      'isFollowing': isTruthy(v['is_following']) || isTruthy(uploader['is_following']),
      'color': Color(colors.$1),
      'accent': Color(colors.$2),
      'networkUrl': v['video_url']?.toString() ?? v['url']?.toString(),
      'filePath': null,
      'fileBytes': null,
    };
  }

  static IconData schoolIcon(String school) {
    final s = school.toLowerCase();
    if (s.contains('engineering')) return Icons.engineering_outlined;
    if (s.contains('business') || s.contains('entrepreneurship')) return Icons.business_center_outlined;
    if (s.contains('agriculture')) return Icons.agriculture_outlined;
    if (s.contains('natural') || s.contains('mathematics')) return Icons.science_outlined;
    if (s.contains('health')) return Icons.local_hospital_outlined;
    if (s.contains('wildlife') || s.contains('environmental')) return Icons.park_outlined;
    if (s.contains('hospitality') || s.contains('tourism')) return Icons.hotel_outlined;
    if (s.contains('art') || s.contains('design')) return Icons.palette_outlined;
    return Icons.school_outlined;
  }

  static Color schoolAccentColor(String school) => Color(_schoolColors(school).$2);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FIX 1/5 — getFeed() & getTrending()
  // PROBLEM TYPE : Frontend integration bug (wrong endpoints)
  // OLD : GET /api/reels?feed=for_you  (query-param approach, not in API spec)
  // NEW : GET /api/reels/for-you  and  GET /api/reels/trending
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<List<Map<String, dynamic>>> getFeed({
    String filter = 'for_you',
    String? school,
    int page = 1,
  }) async {
    final opts = await _authOptions();
    String endpoint;
    final Map<String, dynamic> queryParams = {'page': page};

    if (filter == 'for_you') {
      endpoint = '/api/reels/for-you';
    } else if (filter == 'trending') {
      endpoint = '/api/reels/trending';
    } else {
      endpoint = '/api/reels';
      queryParams['feed'] = filter;
      if (school != null && school.isNotEmpty) queryParams['school'] = school;
    }

    final response = await _dio.get(endpoint, queryParameters: queryParams, options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> toggleLike(dynamic videoId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$videoId/like', options: opts);
  }

  static Future<List<Map<String, dynamic>>> getComments(dynamic videoId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/$videoId/comments', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['comments'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> postComment(dynamic videoId, String body) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      '/api/reels/$videoId/comments',
      data: {'body': body},
      options: opts,
    );
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw['comment'] ?? raw) : {});
  }

  static Future<void> toggleCommentLike(dynamic commentId) async {
    final opts = await _authOptions();
    await _dio.post('/api/comments/$commentId/like', options: opts);
  }

  static Future<void> toggleBookmark(dynamic reelId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$reelId/bookmark', options: opts);
  }

  static Future<void> recordView(dynamic reelId, {int? watchSeconds}) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/reels/$reelId/view',
      data: {if (watchSeconds != null) 'watch_seconds': watchSeconds},
      options: opts,
    );
  }

  static Future<void> recordShare(dynamic reelId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$reelId/share', options: opts);
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/bookmarks', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/notifications', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['notifications'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> markNotificationRead(dynamic id) async {
    final opts = await _authOptions();
    await _dio.post('/api/notifications/read', data: {'ids': [id]}, options: opts);
  }

  static Future<void> markAllNotificationsRead() async {
    final opts = await _authOptions();
    await _dio.post('/api/notifications/read', options: opts);
  }

  static Future<List<Map<String, dynamic>>> searchVideos(String query, {String? school}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/reels/search',
      queryParameters: {'q': query, if (school != null && school.isNotEmpty) 'school': school},
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<Map<String, dynamic>>> getTrending() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/trending', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/progress/dashboard', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  static Future<List<Map<String, dynamic>>> getSuggestedUsers() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/users/suggestions', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getTrendingTopics() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/trending-tags', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['topics'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> toggleFollow(dynamic userId) async {
    final opts = await _authOptions();
    await _dio.post('/api/users/$userId/follow', options: opts);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FIX 2/5 — getAchievements()
  // PROBLEM TYPE : Frontend integration bug (wrong URL)
  // OLD : GET /api/user/achievements  → 404
  // NEW : GET /api/progress/achievements
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<List<Map<String, dynamic>>> getAchievements() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/progress/achievements', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['achievements'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/auth/me', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/users/search',
      queryParameters: {'q': query},
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> getUserPublicProfile(dynamic userId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/users/$userId', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw['user'] ?? raw) : {});
  }

  static Future<List<Map<String, dynamic>>> getUserVideos(dynamic userId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/user/$userId', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FIX 3/5 — getSchools()
  // PROBLEM TYPE : Frontend integration bug (wrong URL)
  // OLD : GET /api/schools  → 404
  // NEW : GET /api/meta/faculties
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<List<Map<String, dynamic>>> getSchools() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/meta/faculties', options: opts);
    final raw = response.data;
    final List list = (raw is Map
        ? (raw['data'] ?? raw['faculties'] ?? raw['schools'] ?? [])
        : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FIX 4/5 — uploadReel()
  // PROBLEM TYPE : Frontend integration bug (wrong field names → causes 422)
  // OLD fields : title, school, module, description  (none exist in API schema)
  // NEW fields : caption (required), duration (required int 1-180), audience
  // API schema : StoreReelRequest requires ['video', 'caption', 'duration']
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<Map<String, dynamic>> uploadReel({
    required String caption,
    required int duration,
    String audience = 'everyone',
    List<String>? hashtags,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final token = await AuthService.getToken();
    final formData = FormData();

    formData.fields.add(MapEntry('caption', caption));
    formData.fields.add(MapEntry('duration', duration.clamp(1, 180).toString()));
    formData.fields.add(MapEntry('audience', audience));

    if (hashtags != null && hashtags.isNotEmpty) {
      for (final tag in hashtags.take(10)) {
        final clean = tag.replaceAll('#', '').trim();
        if (clean.isNotEmpty) formData.fields.add(MapEntry('hashtags[]', clean));
      }
    }

    if (filePath != null) {
      formData.files.add(MapEntry(
        'video',
        await MultipartFile.fromFile(filePath, filename: fileName),
      ));
    } else if (fileBytes != null) {
      formData.files.add(MapEntry(
        'video',
        MultipartFile.fromBytes(fileBytes, filename: fileName),
      ));
    }

    final response = await _dio.post(
      '/api/reels',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) onProgress(sent / total);
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        },
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw['reel'] ?? raw) : {});
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FIX 5/5 — getLikedVideos()
  // PROBLEM TYPE : Backend gap (endpoint missing — not your fault)
  // OLD : GET /api/reels/liked → 404 (backend never created this endpoint)
  // NEW : Graceful fallback to bookmarks until backend adds the endpoint
  // NOTE : Tell your backend dev to add GET /api/reels/liked
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<List<Map<String, dynamic>>> getLikedVideos() async {
    // TODO: When backend adds GET /api/reels/liked, replace with:
    // final opts = await _authOptions();
    // final response = await _dio.get('/api/reels/liked', options: opts);
    // ... parse and return
    return getBookmarks(); // temporary fallback
  }

  static Future<List<Map<String, dynamic>>> getMyVideos() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return [];
    return getUserVideos(userId);
  }

  static Future<List<Map<String, dynamic>>> getFollowers(dynamic userId, {int page = 1}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/users/$userId/followers',
      queryParameters: {'page': page},
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['followers'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getFollowing(dynamic userId, {int page = 1}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/users/$userId/following',
      queryParameters: {'page': page},
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['following'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> logoutFromServer() async {
    try {
      final opts = await _authOptions();
      await _dio.post('/api/auth/logout', options: opts);
    } catch (_) {}
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // updateProfile() — field names fixed
  // PROBLEM TYPE : Frontend integration bug (wrong field names → 422)
  // OLD fields : name, bio, avatar   (wrong — bio not in schema at all)
  // NEW fields : full_name, profile_picture   (per ProfileUpdateRequest schema)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    File? profilePicture,
  }) async {
    final token = await AuthService.getToken();
    final formData = FormData();
    if (fullName != null && fullName.isNotEmpty) {
      formData.fields.add(MapEntry('full_name', fullName));
    }
    if (profilePicture != null) {
      formData.files.add(MapEntry(
        'profile_picture',
        await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        ),
      ));
    }
    final response = await _dio.put(
      '/api/profile',
      data: formData,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      }),
    );
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }
}