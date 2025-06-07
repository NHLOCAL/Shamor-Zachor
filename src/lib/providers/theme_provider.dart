import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent the available theme modes
enum ThemeModeOption { system, light, dark }

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  ThemeModeOption _themeModeOption = ThemeModeOption.system; // Default to system theme

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode {
    switch (_themeModeOption) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeModeOption get themeModeOption => _themeModeOption;

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey);

    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeModeOption.values.length) {
      _themeModeOption = ThemeModeOption.values[themeIndex];
    } else {
      _themeModeOption = ThemeModeOption.system; // Default if nothing is stored or value is invalid
    }
    notifyListeners();
  }

  // Save theme preference to SharedPreferences and notify listeners
  Future<void> setThemeMode(ThemeModeOption themeModeOption) async {
    if (_themeModeOption == themeModeOption) return;

    _themeModeOption = themeModeOption;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, _themeModeOption.index);
    notifyListeners();
  }
}
