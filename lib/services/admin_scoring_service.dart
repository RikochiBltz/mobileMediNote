import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class AdminScoringService {
  AdminScoringService({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  Future<List<UserScoreCard>> fetchScores() async {
    var res = await _getScores();
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      res = await _getScores();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_errorMessage(res, 'Could not load scores'));
    }

    final data = jsonDecode(res.body);
    if (data is! List) {
      throw Exception('Invalid scores response');
    }

    return data
        .map((item) => UserScoreCard.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _getScores() async {
    return http.get(
      Uri.parse('${AppConfig.springBaseUrl}/api/scoring/admin/users'),
      headers: await _auth.authHeaders(json: false),
    );
  }

  String _errorMessage(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['error'] ?? decoded['message'] ?? decoded['detail'])
                ?.toString() ??
            fallback;
      }
    } catch (_) {
      // Keep fallback.
    }
    return fallback;
  }
}

class UserScoreCard {
  final int userId;
  final String email;
  final String fullName;
  final String role;
  final bool enabled;
  final double overallScore;
  final double relevanceScore;
  final double frequencyScore;
  final double coverageScore;
  final int totalSessions;
  final int totalChatQuestions;
  final int activeDays30;
  final String featuresUsed;
  final String rationale;

  UserScoreCard({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.enabled,
    required this.overallScore,
    required this.relevanceScore,
    required this.frequencyScore,
    required this.coverageScore,
    required this.totalSessions,
    required this.totalChatQuestions,
    required this.activeDays30,
    required this.featuresUsed,
    required this.rationale,
  });

  factory UserScoreCard.fromJson(Map<String, dynamic> json) {
    return UserScoreCard(
      userId: _intValue(json['userId']),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'User',
      role: json['role']?.toString() ?? '',
      enabled: json['enabled'] == true,
      overallScore: _doubleValue(json['overallScore']),
      relevanceScore: _doubleValue(json['relevanceScore']),
      frequencyScore: _doubleValue(json['frequencyScore']),
      coverageScore: _doubleValue(json['coverageScore']),
      totalSessions: _intValue(json['totalSessions']),
      totalChatQuestions: _intValue(json['totalChatQuestions']),
      activeDays30: _intValue(json['activeDays30']),
      featuresUsed: json['featuresUsed']?.toString() ?? '',
      rationale: json['rationale']?.toString() ?? '',
    );
  }

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
