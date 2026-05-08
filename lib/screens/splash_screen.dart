import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/engagement_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_design.dart';
import 'admin/admin_dashboard.dart';
import 'delegate/delegate_dashboard.dart';
import 'enterprise/enterprise_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final user = await _auth.currentUser();
    if (!mounted) return;
    if (user != null) {
      await EngagementService.instance.logSessionStart(source: 'restore');
    }

    _replaceWith(_screenForUser(user));
  }

  Widget _screenForUser(User? user) {
    if (user == null) {
      return const LoginScreen();
    }

    switch (user.userRole) {
      case UserRole.delegate:
        return DelegateDashboard(user: user);
      case UserRole.enterprise:
        return EnterpriseDashboard(user: user);
      case UserRole.admin:
        return AdminDashboard(admin: user);
    }
  }

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeInheritedWidget.of(context)?.isDarkMode ?? false;
    final primaryText = AppDesign.textPrimary(isDark);
    final secondaryText = AppDesign.textSecondary(isDark);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.pageGradient(isDark),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppDesign.surface(isDark),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.green.withValues(alpha: 0.2),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: AppDesign.cardBorder(isDark)),
                      ),
                      child: Image.asset(
                        'assets/images/ChatGPT Image Feb 15, 2026, 12_08_14 AM.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.medical_services_rounded,
                          color: AppDesign.green,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'MediNote',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smart Medical Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
