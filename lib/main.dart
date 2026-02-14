import 'package:flutter/material.dart';
import 'services/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    const ThemeInheritedWrapper(
      child: const PharmaApp(),
    ),
  );
}

class ThemeInheritedWrapper extends StatefulWidget {
  final Widget child;

  const ThemeInheritedWrapper({super.key, required this.child});

  @override
  State<ThemeInheritedWrapper> createState() => _ThemeInheritedWrapperState();
}

class _ThemeInheritedWrapperState extends State<ThemeInheritedWrapper> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeInheritedWidget(
      themeProvider: _themeProvider,
      child: widget.child,
    );
  }
}

class PharmaApp extends StatelessWidget {
  const PharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeInheritedWidget.of(context);

    return MaterialApp(
      title: 'PharmaCare',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider?.isDarkMode == true ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
