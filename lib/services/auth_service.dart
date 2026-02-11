import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:8081";
  static const _storage = FlutterSecureStorage();
  Future<void> forgotPassword(String email) async {
    final uri = Uri.parse("$_baseUrl/api/auth/forgot-password");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception("Forgot password failed (${res.statusCode})");
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final uri = Uri.parse("$_baseUrl/api/auth/reset-password");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "newPassword": newPassword}),
    );

    if (res.statusCode != 200) {
      throw Exception("Reset password failed (${res.statusCode})");
    }
  }

  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse("$_baseUrl/api/auth/login");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (res.statusCode != 200) {
      throw Exception("Login failed (${res.statusCode})");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final token = data["accessToken"] as String?;
    final role = data["role"] as String?;
    final mail = data["email"] as String?;

    if (token == null || role == null || mail == null) {
      throw Exception("Invalid login response");
    }

    await _storage.write(key: "accessToken", value: token);
    await _storage.write(key: "role", value: role);
    await _storage.write(key: "email", value: mail);

    return LoginResult(accessToken: token, role: role, email: mail);
  }

  Future<void> logout() async {
    await _storage.delete(key: "accessToken");
    await _storage.delete(key: "role");
    await _storage.delete(key: "email");
  }
}

class LoginResult {
  final String accessToken;
  final String role; // ex: "ADMIN"
  final String email;

  LoginResult({
    required this.accessToken,
    required this.role,
    required this.email,
  });
}
