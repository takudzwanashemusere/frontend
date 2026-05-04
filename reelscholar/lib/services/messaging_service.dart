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

  /// Checks connection status with [receiverUid].
  /// Returns a map with keys: status, conversation_id?, request_id?
  /// status values: no_connection | request_sent | request_received | conversation_exists
  static Future<Map<String, dynamic>> checkConnection(String receiverUid) async {
    final opts = await _authOptions();
    try {
      final response = await _dio.get(
        '/api/message-requests/check/$receiverUid',
        options: opts,
      );
      final raw = response.data;
      // API returns { success, data: { status, conversation_id?, request_id? } }
      if (raw is Map && raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return Map<String, dynamic>.from(raw is Map ? raw : {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return {'status': 'no_connection'};
      rethrow;
    }
  }

  /// Checks if a conversation with [receiverUid] already exists.
  /// Returns the conversation ID (UUID string) or '' if none.
  static Future<String> startConversation(String receiverUid) async {
    try {
      final info = await checkConnection(receiverUid);
      if (info['status'] == 'conversation_exists') {
        return info['conversation_id']?.toString() ?? '';
      }
      return '';
    } catch (_) {
      return '';
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

  /// Reject an incoming message request (POST /message-requests/{id}/reject).
  static Future<void> rejectMessageRequest(dynamic requestId) async {
    final opts = await _authOptions();
    await _dio.post('/api/message-requests/$requestId/reject', options: opts);
  }

  /// Cancel / delete your own outgoing message request (DELETE /message-requests/{id}).
  static Future<void> cancelMessageRequest(dynamic requestId) async {
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

  // ─── Group conversations ────────────────────────────────────────────────────

  /// Create a study group conversation.
  /// [participantIds] = UUIDs of members (excluding creator, max 49).
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> participantIds,
    String? description,
    bool anyoneCanMessage = true,
  }) async {
    final opts = await _authOptions();
    final response = await _dio.post(
      '/api/conversations/group',
      data: {
        'name': name,
        'participant_ids': participantIds,
        if (description != null) 'description': description,
        'anyone_can_message': anyoneCanMessage,
      },
      options: opts,
    );
    final raw = response.data;
    return Map<String, dynamic>.from(
      raw is Map ? (raw['data'] ?? raw) : {},
    );
  }

  /// Update group details (admins / creator only).
  static Future<Map<String, dynamic>> updateGroup(
    String convId, {
    String? name,
    String? description,
    String? avatarUrl,
    bool? anyoneCanMessage,
  }) async {
    final opts = await _authOptions();
    final response = await _dio.put(
      '/api/conversations/$convId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (anyoneCanMessage != null) 'anyone_can_message': anyoneCanMessage,
      },
      options: opts,
    );
    final raw = response.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  /// Leave a group conversation.
  static Future<void> leaveGroup(String convId) async {
    final opts = await _authOptions();
    await _dio.delete('/api/conversations/$convId/leave', options: opts);
  }

  /// Add participants to a group.
  static Future<void> addParticipants(
      String convId, List<String> userIds) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/conversations/$convId/participants',
      data: {'user_ids': userIds},
      options: opts,
    );
  }

  /// List participants in a conversation.
  static Future<List<Map<String, dynamic>>> getParticipants(
      String convId) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/conversations/$convId/participants',
      options: opts,
    );
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Mute / unmute a conversation.
  /// Set [isMuted] to true; optionally pass [mutedUntil] (ISO 8601 datetime).
  static Future<void> muteConversation(
    String convId, {
    required bool isMuted,
    String? mutedUntil,
  }) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/conversations/$convId/mute',
      data: {
        'is_muted': isMuted,
        if (mutedUntil != null) 'muted_until': mutedUntil,
      },
      options: opts,
    );
  }

  /// Get count of pending incoming message requests.
  static Future<int> getPendingRequestCount() async {
    final opts = await _authOptions();
    try {
      final response = await _dio.get(
        '/api/message-requests/pending-count',
        options: opts,
      );
      final raw = response.data;
      return (raw is Map
              ? (raw['data']?['pending_count'] ?? raw['pending_count'] ?? 0)
              : 0)
          as int? ??
          0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Messages ───────────────────────────────────────────────────────────────

  /// Delete a message you sent.
  static Future<void> deleteMessage(String messageId) async {
    final opts = await _authOptions();
    await _dio.delete('/api/messages/$messageId', options: opts);
  }

  /// React to a message (toggles add / update / remove automatically).
  /// [emoji] must be a valid emoji string (max 10 chars).
  static Future<void> reactToMessage(String messageId, String emoji) async {
    final opts = await _authOptions();
    await _dio.post(
      '/api/messages/$messageId/react',
      data: {'emoji': emoji},
      options: opts,
    );
  }

  // ─── Typing indicators ──────────────────────────────────────────────────────

  /// Notify the server that the current user started typing.
  static Future<void> startTyping(String convId) async {
    try {
      final opts = await _authOptions();
      await _dio.post('/api/conversations/$convId/typing/start', options: opts);
    } catch (_) {}
  }

  /// Notify the server that the current user stopped typing.
  static Future<void> stopTyping(String convId) async {
    try {
      final opts = await _authOptions();
      await _dio.post('/api/conversations/$convId/typing/stop', options: opts);
    } catch (_) {}
  }

  /// Get users currently typing in a conversation.
  static Future<List<Map<String, dynamic>>> getTypingUsers(
      String convId) async {
    final opts = await _authOptions();
    final response = await _dio.get(
      '/api/conversations/$convId/typing',
      options: opts,
    );
    final raw = response.data;
    final List list =
        (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ─── Auth helpers ────────────────────────────────────────────────────────────

  /// Update FCM push-notification token.
  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      final opts = await _authOptions();
      await _dio.put(
        '/api/auth/fcm-token',
        data: {'fcm_token': fcmToken},
        options: opts,
      );
    } catch (_) {}
  }

  /// Logout from all devices (revoke all tokens).
  static Future<void> logoutAllDevices() async {
    try {
      final opts = await _authOptions();
      await _dio.post('/api/auth/logout-all', options: opts);
    } catch (_) {}
  }
}
