import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../services/api_constants.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg           = Color(0xFF0D0F14);
const _kFieldBg      = Color(0xFF161A24);
const _kFieldBorder  = Color(0xFF2A2D35);
const _kFieldFocusBg = Color(0xFF161D2E);
const _kFocusBorder  = Color(0xFF3B82F6);
const _kAccent       = Color(0xFF3B82F6);
const _kAccentDeep   = Color(0xFF2563EB);
const _kLabel        = Color(0xFF9CA3AF);
const _kDivLine      = Color(0xFF1F2330);
const _kDivText      = Color(0xFF374151);
const _kMuted        = Color(0xFF6B7280);
const _kError        = Color(0xFFEF4444);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  bool _rememberMe      = false;

  late AnimationController _animController;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final res = await http.post(
          Uri.parse('$kLaravelUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: json.encode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'device_name': 'mobile',
          }),
        );
        if (!mounted) return;
        final data = json.decode(res.body);
        if (res.statusCode == 200 && data['success'] == true) {
          final user = data['user'] ?? {};
          await AuthService.saveSession(
            email: _emailController.text.trim(),
            name: user['name'] ?? user['full_name'] ?? '',
            token: data['token'] ?? '',
            userId: user['id'],
            username: user['username'] ?? user['email'],
          );
          try {
            final email    = _emailController.text.trim();
            final password = _passwordController.text;
            final savedName     = await AuthService.getUserName() ?? '';
            final savedUsername = await AuthService.getUsername() ?? '';
            final msgLoginRes = await http.post(
              Uri.parse('$kBaseUrl/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'email': email, 'password': password}),
            );
            if (msgLoginRes.statusCode == 200) {
              final msgData = json.decode(msgLoginRes.body);
              await AuthService.saveMessagingToken(msgData['access_token'] ?? '');
            } else {
              final safeUsername = savedUsername.isEmpty
                  ? email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
                  : savedUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
              final msgRegRes = await http.post(
                Uri.parse('$kBaseUrl/auth/register'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'email': email,
                  'username': safeUsername,
                  'name': savedName.isNotEmpty ? savedName : email.split('@').first,
                  'password': password,
                }),
              );
              if (msgRegRes.statusCode == 201) {
                final msgData = json.decode(msgRegRes.body);
                await AuthService.saveMessagingToken(msgData['access_token'] ?? '');
              }
            }
          } catch (_) {
            // Non-fatal — messaging will degrade gracefully
          }
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const HomeScreen(),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        } else {
          final message = data['message'] ?? 'Invalid credentials';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.toString())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: IntrinsicHeight(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 36),

                          // Logo
                          const _LogoRow(),

                          const SizedBox(height: 48),

                          // Headline
                          Text(
                            'Welcome back,\nscholar.',
                            style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Sign in with your CUT student account\nto continue learning.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _kLabel,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Email
                          const _FieldLabel('Student Email'),
                          const SizedBox(height: 8),
                          _PremiumTextField(
                            controller: _emailController,
                            hint: 'c22150617n@cut.ac.zw',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email is required';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password
                          const _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          _PremiumTextField(
                            controller: _passwordController,
                            hint: 'Enter your password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _kMuted,
                                size: 18,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password is required';
                              if (val.length < 6) return 'Must be at least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Remember me + forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _rememberMe ? _kAccent : Colors.transparent,
                                        border: Border.all(
                                          color: _rememberMe ? _kAccent : _kFieldBorder,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: _kLabel,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _kAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Sign In button — gradient
                          _GradientButton(
                            onTap: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 28),

                          // Divider "or continue with"
                          Row(
                            children: [
                              Expanded(
                                child: Container(height: 1, color: _kDivLine),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'or continue with',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: _kDivText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(height: 1, color: _kDivLine),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Google button
                          _GoogleButton(onTap: () {}),

                          const Spacer(),

                          // Register link
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _kLabel,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: _kAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushReplacement(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (_, _, _) =>
                                                  const RegisterScreen(),
                                              transitionsBuilder:
                                                  (_, animation, _, child) =>
                                                      FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      ),
                                              transitionDuration:
                                                  const Duration(milliseconds: 400),
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _LogoRow extends StatelessWidget {
  const _LogoRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Reel',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'Scholar',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: _kAccent,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kLabel,
        letterSpacing: 0.08,
      ),
    );
  }
}

// ─── Premium text field with focus state ─────────────────────────────────────

class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  late final FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focus.hasFocus);
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _isFocused ? _kFieldFocusBg : _kFieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? _kFocusBorder : _kFieldBorder,
          width: 1,
        ),
      ),
      child: TextFormField(
        focusNode: _focus,
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.dmSans(
            color: const Color(0xFF4B5563),
            fontSize: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(widget.icon, color: _kMuted, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: widget.suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          errorStyle: GoogleFonts.dmSans(
            fontSize: 11,
            color: _kError,
          ),
        ),
      ),
    );
  }
}

// ─── Gradient Sign In button ──────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _GradientButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap == null
              ? null
              : const LinearGradient(
                  colors: [_kAccent, _kAccentDeep],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onTap == null ? _kFieldBg : null,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ─── Google sign-in button ────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kFieldBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleLogoIcon(size: 20),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Google G logo (CustomPainter) ───────────────────────────────────────────

class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  static const _blue   = Color(0xFF4285F4);
  static const _red    = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green  = Color(0xFF34A853);
  static const _d      = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s  = size.width;
    final c  = Offset(s / 2, s / 2);
    final sw = s * 0.22;
    final r  = s / 2 - sw / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Ring: 340° total coverage, 20° gap centered at 0° (right / 3-o'clock)
    // Gap spans from -10° to 10° — the G opening where the bar exits

    // Red — top section: 350° → 190° going CW (200°)
    // i.e. from just after top-right gap, sweeping CCW through top and down left
    p.color = _red;
    canvas.drawArc(rect, 10 * _d, 200 * _d, false, p);   // 10° → 210°

    // Yellow — bottom-left: 210° → 270° (60°)
    p.color = _yellow;
    canvas.drawArc(rect, 210 * _d, 60 * _d, false, p);   // 210° → 270°

    // Green — bottom-right: 270° → 350° (80°)
    p.color = _green;
    canvas.drawArc(rect, 270 * _d, 80 * _d, false, p);   // 270° → 350°

    // Blue — below gap: 350° → 360°+10° only via bar visual connection
    // Small arc below center: skipped (covered by bar)
    // Blue arc above gap: 350° → 360°(-0°), drawn as tiny arc then bar
    // Keep it simple: just draw the G bar in blue
    // (the ring terminates at 350°, so there's a natural blue-free gap)

    // G bar — blue, horizontal at center height
    final fp = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Bar: from inner circle right edge to outer circle right edge, at cy
    final barW = r + sw / 2; // from center to outer edge
    final barH = sw * 0.88;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx, c.dy - barH / 2, barW, barH),
        const Radius.circular(1.5),
      ),
      fp,
    );

    // Small blue arc at bottom-right to connect the G bar to the ring
    p.color = _blue;
    canvas.drawArc(rect, 350 * _d, 20 * _d, false, p);   // 350° → 370°(=10°)
  }

  @override
  bool shouldRepaint(_) => false;
}
