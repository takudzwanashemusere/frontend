import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'api_constants.dart';

class MessagingService {
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

  /// Returns all conversations for the logged-in user.
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final opts = await _authOptions();
    final response = await _dio.get('/api/conversations', options: opts);
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['conversations'] ?? []) : raw)
            as List? ??
        [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Checks if a conversation with [receiverUid] already exists.
  /// Returns the conversation ID (UUID string) or '' if none.
  static Future<String> startConversation(String receiverUid) async {
    final opts = await _authOptions();
    try {
      final response = await _dio.get(
        '/api/message-requests/check/$receiverUid',
        options: opts,
      );
      final raw = response.data;
      final convId = (raw is Map
              ? (raw['data']?['id'] ??
                  raw['conversation_id'] ??
                  raw['id'])
              : null)
          ?.toString() ??
          '';
      return convId;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return '';
      rethrow;
    }
  }

  /// Fetches messages for [convId], oldest-first.
  static Future<List<Map<String, dynamic>>> getMessages(String convId) async {
    if (convId.isEmpty) return [];
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/conversations/$convId/messages',
      options: opts,
    );
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['messages'] ?? []) : raw)
            as List? ??
        [];
    // API returns newest-first; reverse so oldest is first (natural chat order).
    final msgs =
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return msgs.reversed.toList();
  }

  /// Sends a text message.
  /// If [convId] is empty, creates a new message request using [receiverUid].
  static Future<Map<String, dynamic>> sendMessage(
    String convId,
    String body, {
    String? receiverUid,
  }) async {
    final opts = await _authOptions();
    if (convId.isEmpty && receiverUid != null) {
      final response = await _dio.post(
        '/api/message-requests',
        data: {'receiver_id': receiverUid, 'initial_message': body},
        options: opts,
      );
      final raw = response.data;
      return Map<String, dynamic>.from(
        raw is Map ? (raw['data'] ?? raw['message'] ?? raw) : {},
      );
    }
    final response = await _dio.post(
      '/api/conversations/$convId/messages/text',
      data: {'body': body},
      options: opts,
    );
    final raw = response.data;
    return Map<String, dynamic>.from(
      raw is Map ? (raw['data'] ?? raw['message'] ?? raw) : {},
    );
  }

  /// Searches for users by name or username.
  static Future<List<Map<String, dynamic>>> searchUsers(String q) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/users/search',
      queryParameters: {'q': q},
      options: opts,
    );
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? raw['users'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Fetch pending message requests.
  static Future<List<Map<String, dynamic>>> getMessageRequests() async {
    final opts = await _authOptions();
    final response =
        await _dio.get('/api/message-requests', options: opts);
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Accept a pending message request.
  static Future<void> acceptMessageRequest(dynamic requestId) async {
    final opts = await _authOptions();
    await _dio.post('/api/message-requests/$requestId/accept', options: opts);
  }

  /// Reject / delete a pending message request.
  static Future<void> rejectMessageRequest(dynamic requestId) async {
    final opts = await _authOptions();
    await _dio.delete('/api/message-requests/$requestId', options: opts);
  }

  /// Mark all messages in a conversation as read.
  static Future<void> markAsRead(String convId) async {
    if (convId.isEmpty) return;
    try {
      final opts = await _authOptions();
      await _dio.post('/api/conversations/$convId/read', options: opts);
    } catch (_) {
      // Non-fatal
    }
  }
}
