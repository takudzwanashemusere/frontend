import 'package:flutter/material.dart';

enum AppThemeMode { dark, light }

class ThemeService {
  ThemeService._();

  // Fixed accent – Electric Blue
  static const Color accentColor = Color(0xFF2563EB);
  static const Color accentColorLight = Color(0xFF3B82F6);
  static const Color accentColorDim = Color(0xFF1D4ED8);
  static const Color accentColorGlow = Color(0x332563EB);

  static final ValueNotifier<AppThemeMode> notifier =
      ValueNotifier(AppThemeMode.dark);

  static AppThemeMode get current => notifier.value;
  static bool get isDark => notifier.value == AppThemeMode.dark;

  static void setMode(AppThemeMode mode) {
    notifier.value = mode;
  }

  static void toggle() {
    notifier.value = isDark ? AppThemeMode.light : AppThemeMode.dark;
  }
}
