import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

/// Singleton service that keeps chat history while the app is open.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _auth = AuthService();
  final List<Map<String, dynamic>> messages = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  void initialize({required String userName, required String userRole}) {
    if (_initialized) return;

    messages.addAll([
      {
        'sender': 'bot',
        'text': 'Hello $userName! How can I assist you today?',
        'type': 'greeting',
        'time': DateTime.now(),
      },
      {
        'sender': 'bot',
        'text': "I'm MediNote AI. How can I help you today?",
        'type': 'message',
        'time': DateTime.now(),
      },
    ]);

    _initialized = true;
  }

  Future<String> sendMessage(String prompt) async {
    final res = await _postChat(prompt);

    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      final retry = await _postChat(prompt);
      return _answerFromResponse(retry);
    }

    return _answerFromResponse(res);
  }

  Future<http.Response> _postChat(String prompt) async {
    return http.post(
      Uri.parse('${AppConfig.agentBaseUrl}/api/v1/chat'),
      headers: await _auth.authHeaders(),
      body: jsonEncode({'prompt': prompt, 'include_raw_data': false}),
    );
  }

  String _answerFromResponse(http.Response res) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = data?['detail'] ?? data?['error'] ?? data?['message'];
      throw Exception(message?.toString() ?? 'Chat request failed');
    }

    final answer = data?['answer']?.toString().trim();
    if (answer == null || answer.isEmpty) {
      throw Exception('The AI returned an empty answer');
    }

    return answer;
  }

  /// Call this on logout to reset the chat history.
  void reset() {
    messages.clear();
    _initialized = false;
  }
}
