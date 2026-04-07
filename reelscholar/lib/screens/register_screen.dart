import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../services/api_constants.dart';
import '../main.dart';

// ─── API helpers ──────────────────────────────────────────────────────────────

Future<List<String>> _apiFetchFaculties() async {
  try {
    final res = await http.get(
      Uri.parse('$kLaravelUrl/api/meta/faculties'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final raw = body['faculties'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
    }
  } catch (_) {}
  return [];
}

Future<List<String>> _apiFetchDegreePrograms(String faculty) async {
  try {
    final uri = Uri.parse('$kLaravelUrl/api/meta/programmes')
        .replace(queryParameters: {'faculty': faculty});
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final raw = body['data'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
    }
  } catch (_) {}
  return [];
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedFaculty;
  String? _selectedDegreeProgram;

  List<String> _faculties = [];
  List<String> _degreePrograms = [];
  bool _loadingFaculties = false;
  bool _loadingDegrees = false;
  bool _facultiesLoaded = false;

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
    _schoolIdController.addListener(_onStudentIdChanged);
  }

  void _onStudentIdChanged() {
    if (_facultiesLoaded) return;
    if (_schoolIdController.text.trim().length >= 5) {
      _loadFaculties();
    }
  }

  Future<void> _loadFaculties() async {
    if (_facultiesLoaded || _loadingFaculties) return;
    setState(() => _loadingFaculties = true);
    final list = await _apiFetchFaculties();
    if (mounted) {
      setState(() {
        _faculties = list;
        _loadingFaculties = false;
        _facultiesLoaded = true;
      });
    }
  }

  Future<void> _onFacultySelected(String? faculty) async {
    setState(() {
      _selectedFaculty = faculty;
      _selectedDegreeProgram = null;
      _degreePrograms = [];
    });
    if (faculty == null) return;
    setState(() => _loadingDegrees = true);
    final programs = await _apiFetchDegreePrograms(faculty);
    if (mounted) {
      setState(() {
        _degreePrograms = programs;
        _loadingDegrees = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _schoolIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final res = await http.post(
          Uri.parse('$kLaravelUrl/api/auth/register'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: json.encode({
            'full_name': _nameController.text.trim(),
            'student_id': _schoolIdController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'password_confirmation': _confirmPasswordController.text,
            'faculty': _selectedFaculty,
            'degree_programme': _selectedDegreeProgram,
            'device_name': 'mobile',
          }),
        );
        if (!mounted) return;
        final data = json.decode(res.body);
        if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
          final user = data['user'] ?? {};
          final email = _emailController.text.trim();
          final name = _nameController.text.trim();
          final username = user['username'] ?? _schoolIdController.text.trim();
          await AuthService.saveSession(
            email: email,
            name: name,
            token: data['token'] ?? '',
            userId: user['id'],
            username: username,
          );
          await AuthService.saveDepartment(_selectedFaculty!);
          if (_selectedDegreeProgram != null) {
            await AuthService.saveDegreeProgram(_selectedDegreeProgram!);
          }
          // Also register/login with the messaging API
          try {
            // Try register first; if the account already exists, fall back to login
            final msgRegRes = await http.post(
              Uri.parse('$kBaseUrl/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'email': email,
                'username': username,
                'name': name,
                'password': _passwordController.text,
              }),
            );
            if (msgRegRes.statusCode == 201) {
              final msgData = json.decode(msgRegRes.body);
              await AuthService.saveMessagingToken(msgData['access_token'] ?? '');
            } else {
              // Account may already exist — fall back to login
              final msgLoginRes = await http.post(
                Uri.parse('$kBaseUrl/auth/login'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'email': email,
                  'password': _passwordController.text,
                }),
              );
              if (msgLoginRes.statusCode == 200) {
                final msgData = json.decode(msgLoginRes.body);
                await AuthService.saveMessagingToken(msgData['access_token'] ?? '');
              }
            }
          } catch (_) {
            // Non-fatal
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
          final message = data['message'] ?? 'Registration failed';
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

                          const SizedBox(height: 40),

                          // Page title
                          Text(
                            'Create account',
                            style: AppTextStyles.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register with your CUT student details\nto start learning.',
                            style: AppTextStyles.bodyMedium,
                          ),

                          const SizedBox(height: 32),

                          // Full Name
                          _FieldLabel('Full Name'),
                          const SizedBox(height: 8),
                          _CleanTextField(
                            controller: _nameController,
                            hint: 'e.g. Takudzwa Musere',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (val.trim().split(' ').length < 2) {
                                return 'Enter your first and last name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // School ID
                          _FieldLabel('Student ID'),
                          const SizedBox(height: 8),
                          _CleanTextField(
                            controller: _schoolIdController,
                            hint: 'e.g. C22150617N',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.text,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Student ID is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

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

                          // Faculty dropdown
                          _FieldLabel('Faculty'),
                          const SizedBox(height: 8),
                          _FacultyDropdown(
                            value: _selectedFaculty,
                            faculties: _faculties,
                            isLoading: _loadingFaculties,
                            onChanged: _onFacultySelected,
                            validator: (val) {
                              if (val == null) return 'Please select your faculty';
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Degree programme dropdown
                          _FieldLabel('Degree Programme'),
                          const SizedBox(height: 8),
                          _DegreeProgramDropdown(
                            value: _selectedDegreeProgram,
                            programs: _degreePrograms,
                            isLoading: _loadingDegrees,
                            facultySelected: _selectedFaculty != null,
                            onChanged: (val) =>
                                setState(() => _selectedDegreeProgram = val),
                            validator: (val) {
                              if (val == null) return 'Please select your degree programme';
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password
                          _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          _CleanTextField(
                            controller: _passwordController,
                            hint: 'Create a password',
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
                              if (val.length < 8) {
                                return 'Must be at least 8 characters';
                              }
                              if (!val.contains(RegExp(r'[A-Z]')) || !val.contains(RegExp(r'[a-z]'))) {
                                return 'Must have uppercase and lowercase letters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Confirm Password
                          _FieldLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          _CleanTextField(
                            controller: _confirmPasswordController,
                            hint: 'Repeat your password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              child: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Primary CTA
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Create Account'),
                            ),
                          ),

                          const Spacer(),

                          // Sign in link
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 28, top: 24),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: AppTextStyles.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
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
                                                  const LoginScreen(),
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

// ─── Faculty dropdown ─────────────────────────────────────────────────────────

class _FacultyDropdown extends StatelessWidget {
  final String? value;
  final List<String> faculties;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _FacultyDropdown({
    required this.value,
    required this.faculties,
    required this.onChanged,
    this.isLoading = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(faculties.length),
      initialValue: value,
      onChanged: isLoading ? null : onChanged,
      validator: validator,
      isExpanded: true,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
      dropdownColor: AppColors.surface,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      hint: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Text(
          isLoading ? 'Loading faculties...' : 'Select your faculty',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(
            Icons.school_outlined,
            color: AppColors.textTertiary,
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
      items: faculties
          .map(
            (faculty) => DropdownMenuItem(
              value: faculty,
              child: Text(
                faculty,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Degree programme dropdown ────────────────────────────────────────────────

class _DegreeProgramDropdown extends StatelessWidget {
  final String? value;
  final List<String> programs;
  final bool isLoading;
  final bool facultySelected;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _DegreeProgramDropdown({
    required this.value,
    required this.programs,
    required this.onChanged,
    this.isLoading = false,
    this.facultySelected = false,
    this.validator,
  });

  String get _hint {
    if (!facultySelected) return 'Select faculty first';
    if (isLoading) return 'Loading programmes...';
    return 'Select your programme';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('${programs.length}_$value'),
      initialValue: value,
      onChanged: (isLoading || !facultySelected || programs.isEmpty) ? null : onChanged,
      validator: validator,
      isExpanded: true,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
      dropdownColor: AppColors.surface,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      hint: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Text(
          _hint,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(
            Icons.menu_book_outlined,
            color: AppColors.textTertiary,
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
      items: programs
          .map(
            (prog) => DropdownMenuItem(
              value: prog,
              child: Text(
                prog,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Reusable sub-widgets (mirrors login_screen.dart) ────────────────────────

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
          padding: const EdgeInsets.only(left: 14, right: 10),
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
