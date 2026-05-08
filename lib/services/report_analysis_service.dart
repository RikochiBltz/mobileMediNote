import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class ReportAnalysisService {
  ReportAnalysisService({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  Future<ReportAnalysisResult> analyzeFile(PlatformFile file) async {
    final res = await _upload(file);

    if (res.statusCode == 401 || res.statusCode == 403) {
      await _auth.refreshAccessToken();
      final retry = await _upload(file);
      return _resultFromResponse(retry);
    }

    return _resultFromResponse(res);
  }

  Future<http.Response> _upload(PlatformFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.agentBaseUrl}/api/v1/report-analysis'),
    );
    request.headers.addAll(await _auth.authHeaders(json: false));

    if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else {
      throw Exception('Could not read selected file');
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  ReportAnalysisResult _resultFromResponse(http.Response res) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = data?['detail'] ?? data?['error'] ?? data?['message'];
      throw Exception(message?.toString() ?? 'Report analysis failed');
    }

    if (data == null) {
      throw Exception('Invalid report analysis response');
    }

    return ReportAnalysisResult.fromJson(data);
  }
}

class ReportAnalysisResult {
  final String filename;
  final String extractionSource;
  final String validationStatus;
  final bool isValid;
  final String validationReason;
  final int finalScore;
  final List<String> missingFields;
  final List<String> keywords;
  final Map<String, dynamic> scores;
  final Map<String, dynamic> structuredFields;
  final String originalText;
  final String correctedText;
  final String reformulatedText;
  final List<String> warnings;

  ReportAnalysisResult({
    required this.filename,
    required this.extractionSource,
    required this.validationStatus,
    required this.isValid,
    required this.validationReason,
    required this.finalScore,
    required this.missingFields,
    required this.keywords,
    required this.scores,
    required this.structuredFields,
    required this.originalText,
    required this.correctedText,
    required this.reformulatedText,
    required this.warnings,
  });

  factory ReportAnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = _map(json['analysis']);
    final validation = _map(analysis['validation']);
    final scores = _map(analysis['scores']);
    final text = _map(json['text']);

    return ReportAnalysisResult(
      filename: json['filename']?.toString() ?? 'report',
      extractionSource: json['extraction_source']?.toString() ?? 'unknown',
      validationStatus: validation['status']?.toString() ?? 'UNKNOWN',
      isValid: validation['is_valid'] == true,
      validationReason: validation['reason']?.toString() ?? '',
      finalScore: _intValue(scores['final_score']),
      missingFields: _stringList(analysis['missing_fields']),
      keywords: _stringList(analysis['detected_context_keywords']),
      scores: scores,
      structuredFields: _map(analysis['structured_fields']),
      originalText: text['original']?.toString() ?? '',
      correctedText: text['corrected']?.toString() ?? '',
      reformulatedText: text['reformulated']?.toString() ?? '',
      warnings: _stringList(json['warnings']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
