import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ReelScholarApp());
}

// ─── CLEAN SLATE Design Tokens ───────────────────────────────────────────────

class AppColorsDark {
  static const Color bg = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF252836);
  static const Color border = Color(0xFF1E2230);
  static const Color borderMid = Color(0xFF2A2E3F);
  static const Color accent = ThemeService.accentColor;
  static const Color accentLight = ThemeService.accentColorLight;
  static const Color accentDim = ThemeService.accentColorDim;
  static const Color accentGlow = ThemeService.accentColorGlow;
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF334155);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
}

class AppColorsLight {
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderMid = Color(0xFFCBD5E1);
  static const Color accent = ThemeService.accentColor;
  static const Color accentLight = ThemeService.accentColorLight;
  static const Color accentDim = ThemeService.accentColorDim;
  static const Color accentGlow = ThemeService.accentColorGlow;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFFCBD5E1);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
}

class AppColors {
  // Accent & semantic — mode-independent, const
  static const Color accent = ThemeService.accentColor;
  static const Color accentLight = ThemeService.accentColorLight;
  static const Color accentDim = ThemeService.accentColorDim;
  static const Color accentGlow = ThemeService.accentColorGlow;
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // Dynamic based on mode — delegate to const classes
  static Color get bg =>
      ThemeService.isDark ? AppColorsDark.bg : AppColorsLight.bg;
  static Color get surface =>
      ThemeService.isDark ? AppColorsDark.surface : AppColorsLight.surface;
  static Color get surfaceVariant =>
      ThemeService.isDark ? AppColorsDark.surfaceVariant : AppColorsLight.surfaceVariant;
  static Color get border =>
      ThemeService.isDark ? AppColorsDark.border : AppColorsLight.border;
  static Color get borderMid =>
      ThemeService.isDark ? AppColorsDark.borderMid : AppColorsLight.borderMid;
  static Color get textPrimary =>
      ThemeService.isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
  static Color get textSecondary =>
      ThemeService.isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
  static Color get textTertiary =>
      ThemeService.isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;
  static Color get textMuted =>
      ThemeService.isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
}

class AppTextStylesDark {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColorsDark.textPrimary,
    height: 1.6,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColorsDark.textSecondary,
    height: 1.6,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColorsDark.textSecondary,
    height: 1.5,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.textSecondary,
    letterSpacing: 0.1,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.textTertiary,
    letterSpacing: 0.8,
  );
}

class AppTextStylesLight {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColorsLight.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textPrimary,
    height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textPrimary,
    height: 1.6,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textSecondary,
    height: 1.6,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColorsLight.textSecondary,
    height: 1.5,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColorsLight.textSecondary,
    letterSpacing: 0.1,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorsLight.textTertiary,
    letterSpacing: 0.8,
  );
}

class AppTextStyles {
  static TextStyle get displayLarge =>
      ThemeService.isDark ? AppTextStylesDark.displayLarge : AppTextStylesLight.displayLarge;
  static TextStyle get displayMedium =>
      ThemeService.isDark ? AppTextStylesDark.displayMedium : AppTextStylesLight.displayMedium;
  static TextStyle get headingLarge =>
      ThemeService.isDark ? AppTextStylesDark.headingLarge : AppTextStylesLight.headingLarge;
  static TextStyle get headingMedium =>
      ThemeService.isDark ? AppTextStylesDark.headingMedium : AppTextStylesLight.headingMedium;
  static TextStyle get bodyLarge =>
      ThemeService.isDark ? AppTextStylesDark.bodyLarge : AppTextStylesLight.bodyLarge;
  static TextStyle get bodyMedium =>
      ThemeService.isDark ? AppTextStylesDark.bodyMedium : AppTextStylesLight.bodyMedium;
  static TextStyle get bodySmall =>
      ThemeService.isDark ? AppTextStylesDark.bodySmall : AppTextStylesLight.bodySmall;
  static TextStyle get labelMedium =>
      ThemeService.isDark ? AppTextStylesDark.labelMedium : AppTextStylesLight.labelMedium;
  static TextStyle get labelSmall =>
      ThemeService.isDark ? AppTextStylesDark.labelSmall : AppTextStylesLight.labelSmall;
}

// ─────────────────────────────────────────────────────────────────────────────

class ReelScholarApp extends StatefulWidget {
  const ReelScholarApp({super.key});

  @override
  State<ReelScholarApp> createState() => _ReelScholarAppState();
}

class _ReelScholarAppState extends State<ReelScholarApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.notifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.notifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    final isDark = ThemeService.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
    setState(() {});
  }

  ThemeData _buildTheme(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.borderMid),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: AppColors.borderMid, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark;
    return MaterialApp(
      title: 'ReelScholar',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDark),
      home: const SplashScreen(),
    );
  }
}
