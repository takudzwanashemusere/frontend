import 'dart:io';
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

  // Map school name → (bgColor int, accentColor int)
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

  /// Format a count integer into a short label (e.g. 2400 → "2.4K")
  static String formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count?.toString() ?? '') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  /// Normalise a raw API video object to the format expected by the app
  static Map<String, dynamic> normalizeVideo(Map<String, dynamic> v) {
    final school = v['school']?.toString() ?? v['school_name']?.toString() ?? '';
    final colors = _schoolColors(school);
    final user = (v['user'] is Map) ? v['user'] as Map<String, dynamic> : <String, dynamic>{};
    return {
      'id': v['id'],
      'username': '@${user['username'] ?? v['username'] ?? 'user'}',
      'name': user['name'] ?? v['author_name'] ?? 'Unknown',
      'school': school,
      'subject': v['subject']?.toString() ?? v['module']?.toString() ?? '',
      'title': v['title']?.toString() ?? '',
      'likes': formatCount(v['likes_count'] ?? v['likes'] ?? 0),
      'comments': formatCount(v['comments_count'] ?? v['comments'] ?? 0),
      'shares': formatCount(v['shares_count'] ?? v['shares'] ?? 0),
      'likesCount': (v['likes_count'] ?? v['likes'] ?? 0),
      'isLiked': v['is_liked'] == true,
      'color': Color(colors.$1),
      'accent': Color(colors.$2),
      'networkUrl': v['video_url']?.toString() ?? v['url']?.toString(),
      'filePath': null,
      'fileBytes': null,
    };
  }

  /// Fetch the video feed
  static Future<List<Map<String, dynamic>>> getFeed({
    String filter = 'for_you',
    String? school,
    int page = 1,
  }) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/videos',
      queryParameters: {
        'filter': filter,
        if (school != null && school.isNotEmpty) 'school': school,
        'page': page,
      },
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Toggle like/unlike on a video
  static Future<void> toggleLike(dynamic videoId) async {
    final opts = await _authOptions();
    await _dio.post('/api/videos/$videoId/like', options: opts);
  }

  /// Fetch comments for a video
  static Future<List<Map<String, dynamic>>> getComments(dynamic videoId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/videos/$videoId/comments', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['comments'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Post a comment on a video
  static Future<Map<String, dynamic>> postComment(dynamic videoId, String body) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      '/api/videos/$videoId/comments',
      data: {'body': body},
      options: opts,
    );
    final raw = response.data;
    return Map<String, dynamic>.from(
      raw is Map ? (raw['data'] ?? raw['comment'] ?? raw) : {},
    );
  }

  /// Toggle like/unlike on a comment
  static Future<void> toggleCommentLike(dynamic commentId) async {
    final opts = await _authOptions();
    await _dio.post('/api/comments/$commentId/like', options: opts);
  }

  /// Fetch notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/notifications', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['notifications'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Mark a single notification as read
  static Future<void> markNotificationRead(dynamic id) async {
    final opts = await _authOptions();
    await _dio.patch('/api/notifications/$id/read', options: opts);
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsRead() async {
    final opts = await _authOptions();
    await _dio.patch('/api/notifications/read-all', options: opts);
  }

  /// Search videos
  static Future<List<Map<String, dynamic>>> searchVideos(String query, {String? school}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/videos/search',
      queryParameters: {
        'q': query,
        if (school != null && school.isNotEmpty) 'school': school,
      },
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Fetch trending videos
  static Future<List<Map<String, dynamic>>> getTrending() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/videos/trending', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Fetch the current user's dashboard statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/user/stats', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Fetch suggested users to follow
  static Future<List<Map<String, dynamic>>> getSuggestedUsers() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/users/suggested', options: opts);
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Fetch trending topics
  static Future<List<Map<String, dynamic>>> getTrendingTopics() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/topics/trending', options: opts);
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['topics'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Follow or unfollow a user
  static Future<void> toggleFollow(dynamic userId) async {
    final opts = await _authOptions();
    await _dio.post('/api/users/$userId/follow', options: opts);
  }

  /// Fetch the current user's achievements
  static Future<List<Map<String, dynamic>>> getAchievements() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/user/achievements', options: opts);
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['achievements'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Fetch the current user's full profile (stats included)
  static Future<Map<String, dynamic>> getUserProfile() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/user/profile', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }


  /// Update the current user's profile (name, bio, avatar)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? bio,
    File? avatar,
  }) async {
    final token = await AuthService.getToken();
    final formData = FormData();
    if (name != null && name.isNotEmpty) formData.fields.add(MapEntry('name', name));
    if (bio != null) formData.fields.add(MapEntry('bio', bio));
    if (avatar != null) {
      formData.files.add(MapEntry(
        'avatar',
        await MultipartFile.fromFile(avatar.path,
            filename: avatar.path.split('/').last),
      ));
    }
    final response = await _dio.post(
      '/api/user/profile',
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
