import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class HackathonScreen extends StatefulWidget {
  const HackathonScreen({super.key});

  @override
  State<HackathonScreen> createState() => _HackathonScreenState();
}

class _HackathonScreenState extends State<HackathonScreen> {
  late Duration _remaining;
  Timer? _timer;
  String _userFaculty = '';

  // vote, if  you vote it becomes permanent fro the project 
  final Map<int, bool> _voted = {};

  static const _allProjects = [
    {
      'title': 'AgroSense IoT Platform',
      'team': 'Team Mwana Earth',
      'desc':
          'Smart farming IoT that monitors soil moisture, temperature & pH with real-time SMS alerts to farmers across Zimbabwe.',
      'votes': 247,
      'badge': 'Top Pick',
      'badgeType': 'gold',
      'faculty': 'School of Agriculture Sciences and Technology',
    },
    {
      'title': 'MedAssist ZW',
      'team': 'HealthTech CUT',
      'desc':
          'Mobile app connecting rural patients to telemedicine, with offline symptom checking using a locally-trained ML model.',
      'votes': 189,
      'badge': 'Voting Open',
      'badgeType': 'voting',
      'faculty': 'School of Health Sciences and Technology',
    },
    {
      'title': 'CampusPay Wallet',
      'team': 'FinTech Squad',
      'desc':
          'Campus digital wallet for students — pay fees, buy meals, split costs, integrated with ZimSwitch.',
      'votes': 156,
      'badge': 'Voting Open',
      'badgeType': 'voting',
      'faculty': 'School of Entrepreneurship and Business Sciences',
    },
    {
      'title': 'ReelScholar AI Tutor',
      'team': 'AI Lab CUT',
      'desc':
          'AI tutoring chatbot trained on CUT curriculum, offering 24/7 student support and interactive concept explanations.',
      'votes': 134,
      'badge': 'Open',
      'badgeType': 'open',
      'faculty': 'School of Engineering Science and Technology',
    },
    {
      'title': 'EcoTrack ZW',
      'team': 'GreenTech CUT',
      'desc':
          'Mobile platform for tracking wildlife populations and reporting illegal poaching activities in real time using GPS.',
      'votes': 98,
      'badge': 'Open',
      'badgeType': 'open',
      'faculty': 'School of Wildlife and Environmental Science',
    },
    {
      'title': 'HotelPro Dashboard',
      'team': 'Hospitality Innovators',
      'desc':
          'Smart hotel management system with AI-powered booking forecasts, staff scheduling, and guest feedback analytics.',
      'votes': 76,
      'badge': 'Open',
      'badgeType': 'open',
      'faculty': 'School of Hospitality and Tourism',
    },
  ];

  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(days: 3, hours: 14, minutes: 27, seconds: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
    _loadFacultyProjects();
  }

  Future<void> _loadFacultyProjects() async {
    final faculty = await AuthService.getDepartment();
    final filtered = _allProjects
        .where((p) => p['faculty'] == faculty)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (mounted) {
      setState(() {
        _userFaculty = faculty ?? '';
        // Show faculty projects; if none matched show all (fallback)
        _projects = filtered.isNotEmpty
            ? filtered
            : _allProjects.map((p) => Map<String, dynamic>.from(p)).toList();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _castVote(int index) {
    // Voting is permanent — once cast it cannot be undone
    if (_voted[index] == true) return;
    setState(() => _voted[index] = true);
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hackathon Hub',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero banner ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D2347), Color(0xFF1A3A6B), Color(0xFF2D5FA6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge + title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5A623),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE NOW',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF5A623),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'CUT Innovation\nChallenge 2025',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Submit your project, get voted on by the CUT community',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Countdown + submit button
                      Row(
                        children: [
                          _CountdownUnit(value: _pad(days), label: 'DAYS'),
                          _CountdownSep(),
                          _CountdownUnit(value: _pad(hours), label: 'HRS'),
                          _CountdownSep(),
                          _CountdownUnit(value: _pad(minutes), label: 'MIN'),
                          _CountdownSep(),
                          _CountdownUnit(value: _pad(seconds), label: 'SEC'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showSubmitSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF0D2347),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D2347),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section header ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Your Faculty Challenges',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_projects.length} project${_projects.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (_userFaculty.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _userFaculty,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Project cards grid ───────────────────────────────
            _projects.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'Loading challenges...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final p = _projects[i];
                          final voted = _voted[i] ?? false;
                          final baseVotes = p['votes'] as int;
                          final displayVotes = voted ? baseVotes + 1 : baseVotes;

                          return _ProjectCard(
                            title: p['title'] as String,
                            team: p['team'] as String,
                            desc: p['desc'] as String,
                            votes: displayVotes,
                            badge: p['badge'] as String,
                            badgeType: p['badgeType'] as String,
                            voted: voted,
                            onVote: () => _castVote(i),
                          );
                        },
                        childCount: _projects.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubmitProjectSheet(),
    );
  }
}

// ─── Countdown widgets ────────────────────────────────────────────────────────

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5A623),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            color: Colors.white38,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CountdownSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
        ),
      ),
    );
  }
}

// ─── Project card ─────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final String title;
  final String team;
  final String desc;
  final int votes;
  final String badge;
  final String badgeType;
  final bool voted;
  final VoidCallback onVote;

  const _ProjectCard({
    required this.title,
    required this.team,
    required this.desc,
    required this.votes,
    required this.badge,
    required this.badgeType,
    required this.voted,
    required this.onVote,
  });

  Color get _badgeColor {
    switch (badgeType) {
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'voting':
        return const Color(0xFF22C55E);
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 12,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '$votes votes',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: voted ? null : onVote,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: voted
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: voted
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.borderMid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (voted) ...[
                        Icon(Icons.how_to_vote_rounded,
                            size: 11, color: AppColors.success),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        voted ? 'Voted' : 'Vote',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: voted
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Submit project sheet ─────────────────────────────────────────────────────

class _SubmitProjectSheet extends StatefulWidget {
  @override
  State<_SubmitProjectSheet> createState() => _SubmitProjectSheetState();
}

class _SubmitProjectSheetState extends State<_SubmitProjectSheet> {
  final _titleCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Engineering';

  static const _categories = [
    'Engineering',
    'Business',
    'Medicine',
    'Agriculture',
    'Natural Sciences',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _teamCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Submit Project',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your project details below',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Project Title',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamCtrl,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textTertiary,
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Project Description',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textTertiary,
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Project submitted successfully!',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: const Text('Submit Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
