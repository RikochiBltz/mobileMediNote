import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  Future<List<AppNotification>> fetchNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    var res = await _get('/api/notifications?unreadOnly=$unreadOnly&limit=$limit');
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      res = await _get('/api/notifications?unreadOnly=$unreadOnly&limit=$limit');
    }
    _ensureOk(res, 'Could not load notifications');
    final data = jsonDecode(res.body);
    if (data is! List) throw Exception('Invalid notification response');
    return data
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    var res = await _get('/api/notifications/unread-count');
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      res = await _get('/api/notifications/unread-count');
    }
    _ensureOk(res, 'Could not load unread count');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return int.tryParse(data['unreadCount']?.toString() ?? '') ?? 0;
  }

  Future<void> markRead(int id) async {
    await _post('/api/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    await _post('/api/notifications/read-all', {});
  }

  Future<void> generateMine() async {
    await _post('/api/notifications/generate-mine', {});
  }

  Future<http.Response> _get(String path) async {
    return http.get(
      Uri.parse('${AppConfig.springBaseUrl}$path'),
      headers: await _auth.authHeaders(json: false),
    );
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    var res = await http.post(
      Uri.parse('${AppConfig.springBaseUrl}$path'),
      headers: await _auth.authHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      res = await http.post(
        Uri.parse('${AppConfig.springBaseUrl}$path'),
        headers: await _auth.authHeaders(),
        body: jsonEncode(body),
      );
    }
    _ensureOk(res, 'Notification request failed');
  }

  void _ensureOk(http.Response res, String fallback) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        throw Exception(
          decoded['error'] ??
              decoded['message'] ??
              decoded['detail'] ??
              fallback,
        );
      }
    } catch (_) {
      // Keep fallback.
    }
    throw Exception(fallback);
  }
}

class AppNotification {
  final int id;
  final String type;
  final String priority;
  final String title;
  final String body;
  final String? actionRoute;
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.actionRoute,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'REMINDER',
      priority: json['priority']?.toString() ?? 'NORMAL',
      title: json['title']?.toString() ?? 'MediNote reminder',
      body: json['body']?.toString() ?? '',
      actionRoute: json['actionRoute']?.toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
