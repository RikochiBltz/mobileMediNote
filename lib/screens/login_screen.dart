import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'delegate/delegate_dashboard.dart';
import 'enterprise/enterprise_dashboard.dart';
import 'admin/admin_dashboard.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/engagement_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_design.dart';
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
  bool _isDarkMode = false;
  final _auth = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserRole _selectedRole = UserRole.delegate;
  bool _rememberMe = true;

  static const _green = AppDesign.green;
  static const _greenDark = Color(0xFF1E8449);
  static const _greenLight = AppDesign.greenLight;

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = ThemeInheritedWidget.of(context);
      if (themeProvider != null) {
        setState(() {
          _isDarkMode = themeProvider.isDarkMode;
        });
        themeProvider.addListener(() {
          if (mounted) {
            setState(() {
              _isDarkMode = themeProvider.isDarkMode;
            });
          }
        });
      }
    });
  }

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

  Future<bool> _authenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return true;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return true;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please verify your identity to continue',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return true;
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final biometricPassed = await _authenticateWithBiometrics();
      if (!biometricPassed) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification failed. Login cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _auth.login(
        email,
        password,
        rememberMe: _rememberMe,
      );
      await EngagementService.instance.logSessionStart(source: 'login');

      if (!mounted) return;
      setState(() => _isLoading = false);

      final user = result.user;
      final userRole = user.userRole;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = AppDesign.surface(_isDarkMode);
    final textColor = AppDesign.textPrimary(_isDarkMode);
    final secondaryTextColor = AppDesign.textSecondary(_isDarkMode);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [
                      _green.withOpacity(0.1),
                      _greenLight.withOpacity(0.05),
                      const Color(0xFF121212),
                    ]
                  : [
                      _green.withOpacity(0.15),
                      _greenLight.withOpacity(0.08),
                      Colors.white,
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _greenLight.withOpacity(0.06),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 650),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo & Title with Picture
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_green, _greenLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: Image.asset(
                              'assets/images/login1.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.local_pharmacy,
                                  size: 70,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'PharmaCare',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader =
                                  LinearGradient(
                                    colors: [_green, _greenDark],
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 50),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Medical Note Management',
                          style: TextStyle(
                            fontSize: 15,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? const Color(0xFF1E1E1E).withOpacity(0.82)
                                : Colors.white.withOpacity(0.86),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppDesign.cardBorder(_isDarkMode),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withOpacity(
                                  _isDarkMode ? 0.18 : 0.12,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Role Selector
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: UserRole.values.map((role) {
                                    final isSelected = _selectedRole == role;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedRole = role,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _green
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _roleIcon(role),
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _roleLabel(role),
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _green.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Email address',
                                    hintStyle: TextStyle(
                                      color: secondaryTextColor,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: _green,
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _green.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: TextStyle(
                                      color: secondaryTextColor,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: _green,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _green,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: _green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: _green.withOpacity(0.6),
                                    ),
                                    onChanged: (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: _green.withOpacity(0.4),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Biometric Login
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleLogin,
                                icon: Icon(Icons.fingerprint, color: _green),
                                label: Text(
                                  'Login with Biometrics',
                                  style: TextStyle(color: _green),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                  side: BorderSide(
                                    color: _green.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Footer
                        Text(
                          'PharmaCare © 2024',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
