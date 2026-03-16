import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ReelScholarApp());
}

// ─── CLEAN SLATE Design Tokens ───────────────────────────────────────────────

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceVariant = Color(0xFF252836);
  static const border = Color(0xFF1E2230);
  static const borderMid = Color(0xFF2A2E3F);

  // Accent — Electric Blue
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFF3B82F6);
  static const accentDim = Color(0xFF1D4ED8);
  static const accentGlow = Color(0x332563EB);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF475569);
  static const textMuted = Color(0xFF334155);

  // Semantic
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
}

class AppTextStyles {
  static const displayLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const displayMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static const headingLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const headingMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  static const bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );
  static const bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  static const labelMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  static const labelSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.8,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class ReelScholarApp extends StatelessWidget {
  const ReelScholarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReelScholar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentLight,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
        ),
        textTheme: const TextTheme(
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
            side: const BorderSide(color: AppColors.borderMid),
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
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: const TextStyle(
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
          side: const BorderSide(color: AppColors.borderMid, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
