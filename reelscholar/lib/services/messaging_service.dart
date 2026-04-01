import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_constants.dart';

class MessagingService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns all conversations for the logged-in user.
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/conversations'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to load conversations: ${res.statusCode}');
  }

  /// Creates or fetches an existing DM conversation with [otherUserId].
  /// Returns the conversation_id.
  static Future<int> startConversation(int otherUserId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/conversations'),
      headers: await _headers(),
      body: json.encode({'other_user_id': otherUserId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body)['conversation_id'] as int;
    }
    throw Exception('Failed to start conversation');
  }

  /// Fetches message history for [convId].
  static Future<List<Map<String, dynamic>>> getMessages(int convId) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/conversations/$convId/messages'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to load messages');
  }

  /// Searches for users by name or username.
  static Future<List<Map<String, dynamic>>> searchUsers(String q) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/users/search?q=${Uri.encodeComponent(q)}'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    return [];
  }
}
