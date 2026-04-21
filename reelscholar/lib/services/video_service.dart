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

  /// Normalise a raw API reel/video object to the format expected by the app
  static Map<String, dynamic> normalizeVideo(Map<String, dynamic> v) {
    final school = v['school']?.toString() ?? v['school_name']?.toString() ?? v['faculty']?.toString() ?? '';
    final colors = _schoolColors(school);
    final user = (v['user'] is Map) ? v['user'] as Map<String, dynamic> : <String, dynamic>{};
    return {
      'id': v['id'],
      'userId': user['id'] ?? v['user_id'] ?? v['author_id'],
      'username': '@${user['username'] ?? v['username'] ?? 'user'}',
      'name': user['name'] ?? v['author_name'] ?? 'Unknown',
      'school': school,
      'subject': v['subject']?.toString() ?? v['module']?.toString() ?? '',
      'title': v['title']?.toString() ?? '',
      // New API uses singular like_count/comment_count/share_count; old used plural _count
      'likes': formatCount(v['likes_count'] ?? v['like_count'] ?? v['likes'] ?? 0),
      'comments': formatCount(v['comments_count'] ?? v['comment_count'] ?? v['comments'] ?? 0),
      'shares': formatCount(v['shares_count'] ?? v['share_count'] ?? v['shares'] ?? 0),
      'likesCount': (v['likes_count'] ?? v['like_count'] ?? v['likes'] ?? 0),
      'isLiked': v['is_liked'] == true,
      'isBookmarked': v['is_bookmarked'] == true,
      'isFollowing': v['is_following'] == true || user['is_following'] == true,
      'color': Color(colors.$1),
      'accent': Color(colors.$2),
      'networkUrl': v['video_url']?.toString() ?? v['url']?.toString(),
      'filePath': null,
      'fileBytes': null,
    };
  }

  /// Map a school name to a Flutter icon
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

  /// Map a school name to an accent Color (public wrapper around _schoolColors)
  static Color schoolAccentColor(String school) => Color(_schoolColors(school).$2);

  /// Fetch the reel feed
  static Future<List<Map<String, dynamic>>> getFeed({
    String filter = 'for_you',
    String? school,
    int page = 1,
  }) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/reels',
      queryParameters: {
        'feed': filter, // API renamed 'filter' → 'feed'
        if (school != null && school.isNotEmpty) 'school': school,
        'page': page,
      },
      options: opts,
    );
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Toggle like/unlike on a reel
  static Future<void> toggleLike(dynamic videoId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$videoId/like', options: opts);
  }

  /// Fetch comments for a reel
  static Future<List<Map<String, dynamic>>> getComments(dynamic videoId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/$videoId/comments', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['comments'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Post a comment on a reel
  static Future<Map<String, dynamic>> postComment(dynamic videoId, String body) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      '/api/reels/$videoId/comments',
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

  /// Bookmark or un-bookmark a reel
  static Future<void> toggleBookmark(dynamic reelId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$reelId/bookmark', options: opts);
  }

  /// Record a reel view (call when user watches)
  static Future<void> recordView(dynamic reelId, {int? watchSeconds}) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/reels/$reelId/view',
      data: {'watch_seconds': ?watchSeconds},
      options: opts,
    );
  }

  /// Record a reel share
  static Future<void> recordShare(dynamic reelId) async {
    final opts = await _authOptions();
    await _dio.post('/api/reels/$reelId/share', options: opts);
  }

  /// Fetch bookmarked reels
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/bookmarks', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
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

  /// Search reels
  static Future<List<Map<String, dynamic>>> searchVideos(String query, {String? school}) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/reels/search',
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

  /// Fetch trending reels (uses feed=trending filter)
  static Future<List<Map<String, dynamic>>> getTrending() async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/reels',
      queryParameters: {'feed': 'trending'},
      options: opts,
    );
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

  /// Fetch trending hashtag topics
  static Future<List<Map<String, dynamic>>> getTrendingTopics() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/trending-tags', options: opts);
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

  /// Fetch the current user's profile (via /auth/me)
  static Future<Map<String, dynamic>> getUserProfile() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/auth/me', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }


  /// Search users by name or username
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

  /// Fetch a public user profile by ID
  static Future<Map<String, dynamic>> getUserPublicProfile(dynamic userId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/users/$userId', options: opts);
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw['user'] ?? raw) : {});
  }

  /// Fetch reels uploaded by a specific user
  static Future<List<Map<String, dynamic>>> getUserVideos(dynamic userId) async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/user/$userId', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Fetch schools from the API
  static Future<List<Map<String, dynamic>>> getSchools() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/schools', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['schools'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Upload a new reel to the API
  static Future<Map<String, dynamic>> uploadReel({
    required String title,
    String? description,
    required String school,
    required String module,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final token = await AuthService.getToken();
    final formData = FormData();
    formData.fields.add(MapEntry('title', title));
    formData.fields.add(MapEntry('school', school));
    formData.fields.add(MapEntry('subject', module));
    if (description != null && description.isNotEmpty) {
      formData.fields.add(MapEntry('description', description));
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
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
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

  /// Fetch the current user's liked videos
  static Future<List<Map<String, dynamic>>> getLikedVideos() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/reels/liked', options: opts);
    final raw = response.data;
    final List list = (raw is Map ? (raw['data'] ?? raw['videos'] ?? raw['reels'] ?? []) : raw) as List? ?? [];
    return list.map((e) => normalizeVideo(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Fetch the current user's own uploaded reels
  static Future<List<Map<String, dynamic>>> getMyVideos() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return [];
    return getUserVideos(userId);
  }

  /// Fetch followers of a user (paginated)
  static Future<List<Map<String, dynamic>>> getFollowers(
    dynamic userId, {
    int page = 1,
  }) async {
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

  /// Fetch users that a given user is following (paginated)
  static Future<List<Map<String, dynamic>>> getFollowing(
    dynamic userId, {
    int page = 1,
  }) async {
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

  /// Revoke the server-side auth token
  static Future<void> logoutFromServer() async {
    try {
      final opts = await _authOptions();
      await _dio.post('/api/auth/logout', options: opts);
    } catch (_) {
      // Non-fatal — always clear local storage regardless
    }
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
    // API changed: PUT /api/profile (was POST /api/user/profile)
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
