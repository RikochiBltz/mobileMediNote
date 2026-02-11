import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PharmaApp());
}

class PharmaApp extends StatelessWidget {
  const PharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaCare',
      theme: ThemeData(
        primaryColor: const Color(0xFF27AE60),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF27AE60),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF27AE60),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
