import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = AppConfig.springBaseUrl;
  static const _storage = FlutterSecureStorage();

  Future<void> forgotPassword(String email) async {
    final uri = Uri.parse("$_baseUrl/api/auth/forgot-password");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, "Forgot password failed"));
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
      throw Exception(_errorMessage(res, "Reset password failed"));
    }
  }

  Future<LoginResult> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final uri = Uri.parse("$_baseUrl/api/auth/login");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "rememberMe": rememberMe,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res, "Invalid email or password"));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data["accessToken"] as String?;
    final refreshToken = data["refreshToken"] as String?;
    final role = (data["role"] as String?)?.toUpperCase();
    final mail = data["email"] as String?;

    if (token == null || role == null || mail == null) {
      throw Exception("Invalid login response");
    }

    await _storage.write(key: "accessToken", value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: "refreshToken", value: refreshToken);
    }
    await _storage.write(key: "role", value: role);
    await _storage.write(key: "email", value: mail);

    return LoginResult(
      accessToken: token,
      refreshToken: refreshToken,
      role: role,
      email: mail,
      user: buildUser(email: mail, role: role),
    );
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: "accessToken");
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: "refreshToken");
  }

  Future<Map<String, String>> authHeaders({bool json = true}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Missing access token");
    }

    return {
      if (json) "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<String> refreshAccessToken() async {
    final email = await _storage.read(key: "email");
    final refreshToken = await _storage.read(key: "refreshToken");

    if (email == null ||
        email.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception("No saved session");
    }

    final res = await http.post(
      Uri.parse("$_baseUrl/api/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "refreshToken": refreshToken}),
    );

    if (res.statusCode != 200) {
      await logout();
      throw Exception(_errorMessage(res, "Session expired"));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data["accessToken"] as String?;
    final newRefreshToken = data["refreshToken"] as String?;

    if (token == null || token.isEmpty) {
      await logout();
      throw Exception("Invalid refresh response");
    }

    await _storage.write(key: "accessToken", value: token);
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await _storage.write(key: "refreshToken", value: newRefreshToken);
    }

    return token;
  }

  Future<User?> currentUser() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    var res = await _getCurrentUserResponse(token);
    if (res.statusCode == 401 || res.statusCode == 403) {
      try {
        final refreshedToken = await refreshAccessToken();
        res = await _getCurrentUserResponse(refreshedToken);
      } catch (_) {
        return null;
      }
    }

    if (res.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final email = data["email"] as String? ?? await _storage.read(key: "email");
    final role = (data["role"] as String? ?? await _storage.read(key: "role"))
        ?.toUpperCase();

    if (email == null || role == null) {
      return null;
    }

    await _storage.write(key: "email", value: email);
    await _storage.write(key: "role", value: role);

    return buildUser(email: email, role: role);
  }

  Future<http.Response> _getCurrentUserResponse(String token) {
    return http.get(
      Uri.parse("$_baseUrl/api/auth/me"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  Future<void> logout() async {
    final email = await _storage.read(key: "email");
    if (email != null && email.isNotEmpty) {
      try {
        await http.post(
          Uri.parse("$_baseUrl/api/auth/logout"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email}),
        );
      } catch (_) {
        // Local logout should still complete if the backend is unavailable.
      }
    }

    await _storage.delete(key: "accessToken");
    await _storage.delete(key: "refreshToken");
    await _storage.delete(key: "role");
    await _storage.delete(key: "email");
  }

  User buildUser({required String email, required String role}) {
    final normalizedRole = role.toUpperCase();
    final userRole = _roleToUserRole(normalizedRole);

    return User(
      id: email,
      email: email,
      name: _displayName(email, userRole),
      role: normalizedRole.toLowerCase(),
      userRole: userRole,
      company: "PharmaCare Inc.",
      phone: userRole == UserRole.delegate ? "+33 6 12 34 56 78" : null,
      region: userRole == UserRole.delegate ? "Ile-de-France" : null,
    );
  }

  UserRole _roleToUserRole(String role) {
    switch (role) {
      case "DELEGATE":
        return UserRole.delegate;
      case "STAFF":
        return UserRole.enterprise;
      case "ADMIN":
        return UserRole.admin;
      default:
        throw Exception("Unknown role: $role");
    }
  }

  String _displayName(String email, UserRole role) {
    final prefix = email.split("@").first.trim();
    if (prefix.isNotEmpty) {
      return prefix
          .split(RegExp(r"[._-]+"))
          .where((part) => part.isNotEmpty)
          .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
          .join(" ");
    }

    switch (role) {
      case UserRole.delegate:
        return "Delegate User";
      case UserRole.enterprise:
        return "Staff User";
      case UserRole.admin:
        return "Admin User";
    }
  }

  String _errorMessage(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final error =
            decoded["error"] ?? decoded["message"] ?? decoded["detail"];
        if (error != null) return error.toString();
      }
    } catch (_) {
      // Keep fallback.
    }
    return fallback;
  }
}

class LoginResult {
  final String accessToken;
  final String? refreshToken;
  final String role;
  final String email;
  final User user;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.email,
    required this.user,
  });
}
