import 'package:flutter/material.dart';
import 'delegate/delegate_dashboard.dart';
import 'enterprise/enterprise_dashboard.dart';
import 'admin/admin_dashboard.dart'; // ✅ AJOUTER
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  static const String _baseUrl = "http://10.0.2.2:8081";
  final _storage = const FlutterSecureStorage();

  UserRole _selectedRole = UserRole.delegate;

  static const _green = Color(0xFF27AE60);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.delegate:
        return 'Delegate';
      case UserRole.enterprise:
        return 'Enterprise';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _roleString(UserRole role) {
    // ✅ role string en minuscule pour admin dashboard (delegate/enterprise/admin)
    switch (role) {
      case UserRole.delegate:
        return 'delegate';
      case UserRole.enterprise:
        return 'enterprise';
      case UserRole.admin:
        return 'admin';
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.delegate:
        return Icons.person;
      case UserRole.enterprise:
        return Icons.domain;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("$_baseUrl/api/auth/login");

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (res.statusCode != 200) {
        // Ton SecurityConfig renvoie 401 JSON, donc on affiche juste un message propre
        throw Exception("Invalid email or password");
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data["accessToken"] as String?;
      final role = (data["role"] as String?)?.toUpperCase(); // "ADMIN" ...
      final mail = data["email"] as String?;

      if (token == null || role == null || mail == null) {
        throw Exception("Bad server response");
      }

      // Stockage sécurisé
      await _storage.write(key: "accessToken", value: token);
      await _storage.write(key: "role", value: role);
      await _storage.write(key: "email", value: mail);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Convertir role backend -> UserRole flutter
      final UserRole userRole;
      if (role == "DELEGATE") {
        userRole = UserRole.delegate;
      } else if (role == "STAFF") {
        userRole = UserRole.enterprise;
      } else if (role == "ADMIN") {
        userRole = UserRole.admin;
      } else {
        throw Exception("Unknown role: $role");
      }

      final user = User(
        id: '1',
        email: mail,
        name: userRole == UserRole.delegate
            ? 'Dr. John Smith'
            : userRole == UserRole.enterprise
            ? 'Staff User'
            : 'Admin PharmaCare',
        role: role.toLowerCase(), // si tu utilises minuscule dans l'app
        userRole: userRole,
        company: 'PharmaCare Inc.',
        phone: userRole == UserRole.delegate ? '+33 6 12 34 56 78' : null,
        region: userRole == UserRole.delegate ? 'Île-de-France' : null,
      );

      // Navigation selon role backend
      if (userRole == UserRole.delegate) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DelegateDashboard(user: user)),
        );
      } else if (userRole == UserRole.enterprise) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EnterpriseDashboard(user: user)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminDashboard(admin: user)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    }
  }

  Widget _roleButton(UserRole role) {
    final selected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _roleIcon(role),
                color: selected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _roleLabel(role),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                painter: TopShapePainter(),
                size: const Size(200, 150),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: CustomPaint(
                painter: BottomWavesPainter(),
                size: const Size(400, 100),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Illustration Section
                      Center(
                        child: Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withOpacity(0.08),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/login1.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_pharmacy,
                                      size: 80,
                                      color: _green,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'PharmaCare',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: _green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Role Selection (✅ 3 boutons)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            _roleButton(UserRole.delegate),
                            const SizedBox(width: 8),
                            _roleButton(UserRole.enterprise),
                            const SizedBox(width: 8),
                            _roleButton(UserRole.admin),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Email Field
                      Text(
                        'Email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'your@email.com',
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _green,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      Text(
                        'Password',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: _green,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                     Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        ),
      );
    },
    child: const Text(
      'Forgot Password?',
      style: TextStyle(
        color: _green,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),


                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for top decoration
class TopShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF27AE60).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.5,
      size.width * 0.4,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for bottom waves
class BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF27AE60).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
