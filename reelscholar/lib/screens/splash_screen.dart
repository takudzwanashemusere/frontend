import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _wordmarkController;
  late AnimationController _subtitleController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _wordmarkOpacity;
  late Animation<Offset> _wordmarkSlide;
  late Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();

    // Logo: clean fade + subtle scale (no elastic)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Wordmark: fade + rise
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );

    // Subtitle: fade only
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Sequence
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _wordmarkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _subtitleController.forward();
    });

    // Navigate after 2.8s
    Timer(const Duration(milliseconds: 2800), () async {
      if (mounted) {
        final loggedIn = await AuthService.isLoggedIn();
        final destination = loggedIn ? const HomeScreen() : const LoginScreen();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => destination,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _wordmarkController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Subtle top-right accent glow — very restrained
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _LogoMark(),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Wordmark
                AnimatedBuilder(
                  animation: _wordmarkController,
                  builder: (_, __) => FadeTransition(
                    opacity: _wordmarkOpacity,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: const _Wordmark(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle tag
                AnimatedBuilder(
                  animation: _subtitleController,
                  builder: (_, __) => Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const _SubtitleTag(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom footer
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _subtitleController,
              builder: (_, __) => Opacity(
                opacity: _subtitleOpacity.value,
                child: const _BottomFooter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play icon + book motif
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Reel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Scholar',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w300,
              color: AppColors.accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleTag extends StatelessWidget {
  const _SubtitleTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'CHINHOYI UNIVERSITY OF TECHNOLOGY',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _BottomFooter extends StatelessWidget {
  const _BottomFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thin progress line
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 120),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Learn · Share · Grow',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
