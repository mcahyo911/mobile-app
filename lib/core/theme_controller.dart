import 'package:flutter/material.dart';

class ThemeController {
  // Singleton instance
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  // Mode tema saat ini: Default mengikuti sistem atau Light Mode
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  void setTheme(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}