import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The available theme modes for the app
enum ThemePreference {
  system,
  light,
  dark,
}

/// Provider to manage the app's theme settings
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  bool _isDarkMode = true;
  
  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getBool(_themeKey);
    
    if (savedThemeMode != null) {
      _isDarkMode = savedThemeMode;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      
      notifyListeners();
    }
  }
}

/// Light theme data for the app
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
);

/// Dark theme data for the app
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardTheme(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
); 