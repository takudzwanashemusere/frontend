import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/api_constants.dart';

const _kBg          = Color(0xFF0D0F14);
const _kFieldBg     = Color(0xFF161A24);
const _kFieldBorder = Color(0xFF2A2D35);
const _kFocusBorder = Color(0xFF3B82F6);
const _kAccent      = Color(0xFF3B82F6);
const _kAccentDeep  = Color(0xFF2563EB);
const _kLabel       = Color(0xFF9CA3AF);
const _kMuted       = Color(0xFF6B7280);
const _kError       = Color(0xFFEF4444);
const _kSuccess     = Color(0xFF22C55E);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animController;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$kLaravelUrl/api/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': _emailController.text.trim()}),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => _emailSent = true);
      } else {
        final data = json.decode(res.body);
        final msg  = data['message']?.toString() ?? 'Something went wrong. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: _kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: _kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kLabel, size: 18),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: _kAccent, size: 26),
          ),

          const SizedBox(height: 24),

          Text(
            'Reset password',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your student email address and we\'ll\nsend you a link to reset your password.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _kLabel,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 36),

          _FieldLabel('Student Email'),
          const SizedBox(height: 8),
          _FocusTextField(
            controller: _emailController,
            hint: 'c22150617n@cut.ac.zw',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@'))       return 'Enter a valid email address';
              return null;
            },
          ),

          const SizedBox(height: 28),

          _GradientButton(
            onTap: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Send Reset Link',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _kSuccess.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kSuccess.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: _kSuccess, size: 26),
        ),

        const SizedBox(height: 24),

        Text(
          'Check your inbox',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists for ${_emailController.text.trim()}, '
          'you\'ll receive a password reset link shortly.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: _kLabel,
            height: 1.55,
          ),
        ),

        const SizedBox(height: 32),

        _GradientButton(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Sign In',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: _handleSubmit,
            child: Text(
              'Resend email',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _kAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kLabel,
          letterSpacing: 0.08,
        ),
      );
}

class _FocusTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FocusTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_FocusTextField> createState() => _FocusTextFieldState();
}

class _FocusTextFieldState extends State<_FocusTextField> {
  late final FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _isFocused = _focus.hasFocus));
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
      decoration: BoxDecoration(
        color: _isFocused ? const Color(0xFF161D2E) : _kFieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? _kFocusBorder : _kFieldBorder,
        ),
      ),
      child: TextFormField(
        focusNode: _focus,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.dmSans(color: const Color(0xFF4B5563), fontSize: 14),
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
          errorStyle: GoogleFonts.dmSans(fontSize: 11, color: _kError),
        ),
      ),
    );
  }
}

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
