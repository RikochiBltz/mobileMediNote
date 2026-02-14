import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String _key = 'isDarkMode';
  bool _isDarkMode = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final String? storedTheme = await _storage.read(key: _key);
      if (storedTheme != null) {
        _isDarkMode = storedTheme == 'true';
        notifyListeners();
      }
    } catch (e) {
      _isDarkMode = false;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _storage.write(key: _key, value: _isDarkMode.toString());
  }

  static final ThemeData lightTheme = ThemeData(
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
    scaffoldBackgroundColor: Colors.grey[50],
    cardColor: Colors.white,
    dividerColor: Colors.grey[200],
    iconTheme: const IconThemeData(
      color: Color(0xFF27AE60),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF27AE60),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF27AE60),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey[800],
    iconTheme: const IconThemeData(
      color: Color(0xFF27AE60),
    ),
  );
}

// Inherited widget for accessing theme without provider
class ThemeInheritedWidget extends InheritedWidget {
  final ThemeProvider themeProvider;

  const ThemeInheritedWidget({
    super.key,
    required this.themeProvider,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeInheritedWidget>()
        ?.themeProvider;
  }

  @override
  bool updateShouldNotify(ThemeInheritedWidget oldWidget) {
    return oldWidget.themeProvider != themeProvider;
  }
}
