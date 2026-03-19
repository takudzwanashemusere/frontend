import 'package:flutter/material.dart';

class AppAccentTheme {
  final String name;
  final String emoji;
  final Color accent;
  final Color accentLight;
  final Color accentDim;
  final Color accentGlow;

  const AppAccentTheme({
    required this.name,
    required this.emoji,
    required this.accent,
    required this.accentLight,
    required this.accentDim,
    required this.accentGlow,
  });
}

class ThemeService {
  ThemeService._();

  static const List<AppAccentTheme> themes = [
    AppAccentTheme(
      name: 'Electric Blue',
      emoji: '⚡',
      accent: Color(0xFF2563EB),
      accentLight: Color(0xFF3B82F6),
      accentDim: Color(0xFF1D4ED8),
      accentGlow: Color(0x332563EB),
    ),
    AppAccentTheme(
      name: 'Violet',
      emoji: '💜',
      accent: Color(0xFF7C3AED),
      accentLight: Color(0xFF8B5CF6),
      accentDim: Color(0xFF6D28D9),
      accentGlow: Color(0x337C3AED),
    ),
    AppAccentTheme(
      name: 'Rose',
      emoji: '🌹',
      accent: Color(0xFFE11D48),
      accentLight: Color(0xFFF43F5E),
      accentDim: Color(0xFFBE123C),
      accentGlow: Color(0x33E11D48),
    ),
    AppAccentTheme(
      name: 'Emerald',
      emoji: '💚',
      accent: Color(0xFF059669),
      accentLight: Color(0xFF10B981),
      accentDim: Color(0xFF047857),
      accentGlow: Color(0x33059669),
    ),
    AppAccentTheme(
      name: 'Amber',
      emoji: '🔥',
      accent: Color(0xFFD97706),
      accentLight: Color(0xFFF59E0B),
      accentDim: Color(0xFFB45309),
      accentGlow: Color(0x33D97706),
    ),
    AppAccentTheme(
      name: 'Cyan',
      emoji: '🩵',
      accent: Color(0xFF0891B2),
      accentLight: Color(0xFF06B6D4),
      accentDim: Color(0xFF0E7490),
      accentGlow: Color(0x330891B2),
    ),
    AppAccentTheme(
      name: 'Pink',
      emoji: '🌸',
      accent: Color(0xFFDB2777),
      accentLight: Color(0xFFEC4899),
      accentDim: Color(0xFFBE185D),
      accentGlow: Color(0x33DB2777),
    ),
  ];

  static final ValueNotifier<AppAccentTheme> notifier =
      ValueNotifier(themes[0]);

  static AppAccentTheme get current => notifier.value;

  static void setTheme(AppAccentTheme theme) {
    notifier.value = theme;
  }
}
