import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'home_screen.dart';

// CUT departments with their associated schools and subjects
const _departments = [
  {
    'school': 'School of Engineering Science and Technology',
    'short': 'Engineering & ICT',
    'description': 'Software Engineering, ICT, Networking & more',
    'icon': Icons.engineering_rounded,
    'color': 0xFF1A1040,
    'accent': 0xFF6C63FF,
  },
  {
    'school': 'School of Agriculture Sciences and Technology',
    'short': 'Agriculture',
    'description': 'Crop Science, Soil Science, Animal Science & more',
    'icon': Icons.grass_rounded,
    'color': 0xFF0D2818,
    'accent': 0xFF2ECC71,
  },
  {
    'school': 'School of Entrepreneurship and Business Sciences',
    'short': 'Business',
    'description': 'Business Management, Entrepreneurship, Accounting & more',
    'icon': Icons.business_center_rounded,
    'color': 0xFF1A0A00,
    'accent': 0xFFFF6B35,
  },
  {
    'school': 'School of Health Sciences and Technology',
    'short': 'Health Sciences',
    'description': 'Public Health, Nursing Science & more',
    'icon': Icons.health_and_safety_rounded,
    'color': 0xFF1A0020,
    'accent': 0xFFE040FB,
  },
  {
    'school': 'School of Wildlife and Environmental Science',
    'short': 'Wildlife & Environment',
    'description': 'Wildlife Management, Ecology, Conservation & more',
    'icon': Icons.nature_rounded,
    'color': 0xFF001A2A,
    'accent': 0xFF00BCD4,
  },
  {
    'school': 'School of Hospitality and Tourism',
    'short': 'Hospitality & Tourism',
    'description': 'Hotel Management, Tourism Management & more',
    'icon': Icons.hotel_rounded,
    'color': 0xFF1A1500,
    'accent': 0xFFFFB300,
  },
];

class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  State<DepartmentSelectionScreen> createState() =>
      _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedSchool;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedSchool == null) return;
    setState(() => _isSaving = true);
    await AuthService.saveDepartment(_selectedSchool!);
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
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
                      ),

                      const SizedBox(height: 36),

                      const Text(
                        'Choose your\nDepartment',
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'We\'ll personalise your feed to show content\nrelevant to your programme.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Department list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      final school = dept['school'] as String;
                      final isSelected = _selectedSchool == school;
                      final accent = Color(dept['accent'] as int);
                      final bgColor = Color(dept['color'] as int);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DepartmentCard(
                          school: school,
                          shortName: dept['short'] as String,
                          description: dept['description'] as String,
                          icon: dept['icon'] as IconData,
                          accent: accent,
                          bgColor: bgColor,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedSchool = school),
                        ),
                      );
                    },
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: AnimatedOpacity(
                    opacity: _selectedSchool != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedSchool != null && !_isSaving
                            ? _handleContinue
                            : null,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue to ReelScholar'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final String school;
  final String shortName;
  final String description;
  final IconData icon;
  final Color accent;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.school,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.accent,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.2)
                    : accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accent : AppColors.borderMid,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
