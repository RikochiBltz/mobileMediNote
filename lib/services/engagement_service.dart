import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class EngagementService {
  EngagementService._();

  static final EngagementService instance = EngagementService._();

  final _auth = AuthService();

  Future<void> logSessionStart({String source = 'open'}) {
    return _post(
      eventType: 'session_start',
      feature: 'app',
      metadata: {'source': source},
    );
  }

  Future<void> logFeature(String feature, {Map<String, dynamic>? metadata}) {
    return _post(
      eventType: 'feature_visit',
      feature: feature,
      metadata: metadata ?? const {},
    );
  }

  Future<void> _post({
    required String eventType,
    required String feature,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      var res = await _send(eventType, feature, metadata);
      if (res.statusCode == 401 || res.statusCode == 403) {
        await _auth.refreshAccessToken();
        res = await _send(eventType, feature, metadata);
      }
    } catch (_) {
      // Engagement logging should never interrupt the user's workflow.
    }
  }

  Future<http.Response> _send(
    String eventType,
    String feature,
    Map<String, dynamic> metadata,
  ) async {
    return http.post(
      Uri.parse('${AppConfig.springBaseUrl}/api/scoring/events'),
      headers: await _auth.authHeaders(),
      body: jsonEncode({
        'eventType': eventType,
        'feature': feature,
        'surface': 'mobile',
        'metadata': metadata,
      }),
    );
  }
}
