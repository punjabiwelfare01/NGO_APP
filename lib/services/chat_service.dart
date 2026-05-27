import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../app_state.dart';
import '../core/config.dart';
import '../models/chat_message.dart';
import '../repositories/api_client.dart';

/// Manages a single WebSocket chat connection.
/// Call [connect] once, listen to [messages], send with [send], then [dispose].
class ChatService {
  ChatService({required this.otherUserId});

  final int otherUserId;

  final _controller = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _controller.stream;

  WebSocketChannel? _channel;
  bool _disposed = false;

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> connect() async {
    final token = AppState.token ?? '';
    final uri = Uri.parse(
      '${AppConfig.wsBaseUrl}/ws/chat/$otherUserId?token=${Uri.encodeComponent(token)}',
    );
    _channel = WebSocketChannel.connect(uri);

    // The first message from the server is always {"type":"history","messages":[...]}
    // Subsequent messages are {"type":"message", ...fields}
    // We return the history synchronously via a completer and stream new messages.
    final historyCompleter = Completer<List<ChatMessage>>();
    bool historyReceived = false;

    _channel!.stream.listen(
      (raw) {
        if (_disposed) return;
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;
          if (type == 'history' && !historyReceived) {
            historyReceived = true;
            final list = (data['messages'] as List<dynamic>)
                .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
                .toList();
            historyCompleter.complete(list);
          } else if (type == 'message') {
            _controller.add(ChatMessage.fromJson(data));
          }
        } catch (_) {}
      },
      onError: (_) {
        if (!historyCompleter.isCompleted) {
          historyCompleter.complete([]);
        }
      },
      onDone: () {
        if (!historyCompleter.isCompleted) {
          historyCompleter.complete([]);
        }
      },
    );

    return historyCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => [],
    );
  }

  void send(String content) {
    _channel?.sink.add(jsonEncode({'content': content}));
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    _controller.close();
  }

  // ── Static REST calls ────────────────────────────────────────────────────────

  static Future<List<ConversationSummary>> getConversations() async {
    final list = await ApiClient.get('/chat/conversations') as List<dynamic>;
    return list
        .map((j) => ConversationSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
