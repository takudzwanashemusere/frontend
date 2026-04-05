import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'department_selection_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../services/api_constants.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

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
          // Also authenticate with the messaging API
          try {
            final email = _emailController.text.trim();
            final password = _passwordController.text;
            // Use values from AuthService (saved from form / API response)
            final savedName = await AuthService.getUserName() ?? '';
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
              // Account doesn't exist in messaging DB yet — register it
              // Sanitise username: keep only alphanumeric + underscore
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
          final hasDept = await AuthService.hasDepartment();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) =>
                  hasDept ? const HomeScreen() : const DepartmentSelectionScreen(),
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
      backgroundColor: AppColors.bg,
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
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 36),

                          // Header row — logomark + wordmark
                          _LogoRow(),

                          const SizedBox(height: 52),

                          // Page title
                          Text(
                            'Welcome back',
                            style: AppTextStyles.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in with your CUT student account\nto continue learning.',
                            style: AppTextStyles.bodyMedium,
                          ),

                          const SizedBox(height: 40),

                          // Email
                          _FieldLabel('Student Email'),
                          const SizedBox(height: 8),
                          _CleanTextField(
                            controller: _emailController,
                            hint: 'c22150617n@cut.ac.zw',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password
                          _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          _CleanTextField(
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
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              if (val.length < 6) {
                                return 'Must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Remember me + forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (val) =>
                                          setState(() => _rememberMe = val!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Primary CTA
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Google SSO
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.g_mobiledata_rounded,
                                size: 26,
                                color: AppColors.textSecondary,
                              ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Register link
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: AppTextStyles.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.accent,
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
                                                  const Duration(
                                                    milliseconds: 400,
                                                  ),
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

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _LogoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Reel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'Scholar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CleanTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: AppColors.textTertiary, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }
}
