import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_constants.dart';

/// Singleton WebSocket service.
/// Connect once after login; listen from any screen.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of all incoming events from the server.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  /// Opens a WebSocket connection authenticated with [token].
  void connect(String token) {
    if (isConnected) return; // already connected
    _channel = WebSocketChannel.connect(Uri.parse('$kWsUrl?token=$token'));
    _channel!.stream.listen(
      (data) {
        try {
          final event = json.decode(data as String) as Map<String, dynamic>;
          _controller.add(event);
        } catch (_) {}
      },
      onDone: () => _channel = null,
      onError: (_) => _channel = null,
      cancelOnError: false,
    );
  }

  /// Sends a chat message to [conversationId] via WebSocket.
  void sendMessage(int conversationId, String text) {
    _channel?.sink.add(json.encode({
      'type': 'message',
      'conversation_id': conversationId,
      'text': text,
    }));
  }

  /// Closes the WebSocket connection.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
