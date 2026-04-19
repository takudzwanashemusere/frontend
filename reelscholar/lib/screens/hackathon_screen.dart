import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/hackathon_service.dart';

class HackathonScreen extends StatefulWidget {
  final bool embedded;
  const HackathonScreen({super.key, this.embedded = false});

  @override
  State<HackathonScreen> createState() => _HackathonScreenState();
}

class _HackathonScreenState extends State<HackathonScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _event = {};
  List<Map<String, dynamic>> _projects = [];
  String _userFaculty = '';

  // voted[projectId] = true once the user votes
  final Map<dynamic, bool> _voted = {};

  // Countdown
  Duration _remaining = Duration.zero;
  Timer? _timer;

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final faculty = await AuthService.getDepartment();
      final results = await Future.wait([
        HackathonService.getEvent(),
        HackathonService.getProjects(faculty: faculty),
      ]);

      final event = results[0] as Map<String, dynamic>;
      final projects = (results[1] as List).cast<Map<String, dynamic>>();

      // Start countdown from API deadline
      _timer?.cancel();
      final deadlineStr = event['deadline'] as String?;
      if (deadlineStr != null) {
        final deadline = DateTime.tryParse(deadlineStr);
        if (deadline != null) {
          final remaining = deadline.difference(DateTime.now());
          _remaining = remaining.isNegative ? Duration.zero : remaining;
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (_remaining.inSeconds > 0) {
              setState(() => _remaining -= const Duration(seconds: 1));
            } else {
              _timer?.cancel();
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          _event = event;
          _projects = projects;
          _userFaculty = faculty ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load hackathon data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // ── Voting ────────────────────────────────────────────────────────────────
  void _castVote(dynamic projectId, int index) async {
    if (_voted[projectId] == true) return;

    // Optimistic update
    setState(() {
      _voted[projectId] = true;
      final current = _projects[index]['votes_count'] as int? ??
          _projects[index]['votes'] as int? ?? 0;
      _projects[index] = {
        ..._projects[index],
        'votes_count': current + 1,
        'votes': current + 1,
      };
    });

    try {
      await HackathonService.voteForProject(projectId);
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _voted.remove(projectId);
          final current = _projects[index]['votes_count'] as int? ??
              _projects[index]['votes'] as int? ?? 1;
          _projects[index] = {
            ..._projects[index],
            'votes_count': current - 1,
            'votes': current - 1,
          };
        });
        _showSnack('Could not cast vote. Please try again.');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppColors.surfaceVariant,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _eventTitle =>
      _event['title'] as String? ??
      _event['name'] as String? ??
      'Hackathon Hub';

  String get _eventSubtitle =>
      _event['description'] as String? ??
      _event['subtitle'] as String? ??
      'Submit your project, get voted on by the CUT community';

  bool get _isLive {
    final status = (_event['status'] as String? ?? '').toLowerCase();
    if (status == 'live' || status == 'active' || status == 'open') return true;
    return _remaining.inSeconds > 0;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
            // ── Top bar ───────────────────────────────────────────
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

            if (_isLoading)
              SliverFillRemaining(child: _buildLoadingView())
            else if (_error != null)
              SliverFillRemaining(child: _buildErrorView())
            else ...[
              // ── Hero banner ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0D2347),
                          Color(0xFF1A3A6B),
                          Color(0xFF2D5FA6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live badge
                        if (_isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
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
                        Text(
                          _eventTitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _eventSubtitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (_remaining.inSeconds > 0) ...[
                              _CountdownUnit(value: _pad(days), label: 'DAYS'),
                              _CountdownSep(),
                              _CountdownUnit(value: _pad(hours), label: 'HRS'),
                              _CountdownSep(),
                              _CountdownUnit(value: _pad(minutes), label: 'MIN'),
                              _CountdownSep(),
                              _CountdownUnit(value: _pad(seconds), label: 'SEC'),
                            ] else
                              const Text(
                                'Submissions closed',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                            const Spacer(),
                            if (_remaining.inSeconds > 0)
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
                                      Icon(Icons.add_rounded,
                                          color: Color(0xFF0D2347), size: 16),
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

              // ── Project cards ────────────────────────────────────
              _projects.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No projects yet',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to submit a project!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textMuted,
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
                            final projectId = p['id'];
                            final voted = _voted[projectId] ?? false;
                            final votes = p['votes_count'] as int? ??
                                p['votes'] as int? ?? 0;
                            final badge = p['badge'] as String? ??
                                p['status'] as String? ?? 'Open';
                            final badgeType = p['badge_type'] as String? ??
                                p['badgeType'] as String? ?? 'open';

                            return _ProjectCard(
                              title: p['title'] as String? ?? '',
                              team: p['team'] as String? ??
                                  p['team_name'] as String? ?? '',
                              desc: p['description'] as String? ??
                                  p['desc'] as String? ?? '',
                              votes: votes,
                              badge: badge,
                              badgeType: badgeType,
                              voted: voted,
                              onVote: () => _castVote(projectId, i),
                            );
                          },
                          childCount: _projects.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Loading / error views ─────────────────────────────────────────────────
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading hackathon...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadData,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
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
      builder: (_) => _SubmitProjectSheet(
        onSubmitted: _loadData,
      ),
    );
  }
}

// ─── Countdown widgets ─────────────────────────────────────────────────────────

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

// ─── Project card ──────────────────────────────────────────────────────────────

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
    switch (badgeType.toLowerCase()) {
      case 'gold':
      case 'top':
        return const Color(0xFFF59E0B);
      case 'voting':
      case 'open':
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
              Icon(Icons.favorite_rounded,
                  size: 12, color: AppColors.textTertiary),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

// ─── Submit project sheet ──────────────────────────────────────────────────────

class _SubmitProjectSheet extends StatefulWidget {
  final VoidCallback onSubmitted;
  const _SubmitProjectSheet({required this.onSubmitted});

  @override
  State<_SubmitProjectSheet> createState() => _SubmitProjectSheetState();
}

class _SubmitProjectSheetState extends State<_SubmitProjectSheet> {
  final _titleCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  // Categories match the school names used across the app
  static const _categories = [
    'School of Natural Sciences and Mathematics',
    'School of Engineering Science and Technology',
    'School of Entrepreneurship and Business Sciences',
    'School of Agriculture Sciences and Technology',
    'School of Wildlife and Environmental Science',
    'School of Health Sciences and Technology',
    'School of Hospitality and Tourism',
    'School of Art and Design',
  ];

  String _category = _categories[0];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _teamCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final team = _teamCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || team.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill in all fields.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await HackathonService.submitProject(
        title: title,
        team: team,
        category: _category,
        description: desc,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Project submitted successfully!',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Submission failed. Please try again.',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Project Title',
                labelStyle: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamCtrl,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                  fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                  fontSize: 13),
              dropdownColor: AppColors.surface,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Faculty / School',
                labelStyle: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textTertiary),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ))
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
                  fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Project Description',
                labelStyle: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textTertiary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
