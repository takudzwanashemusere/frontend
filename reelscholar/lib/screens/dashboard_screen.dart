import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../main.dart';
import 'search_screen.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'Student';

  // Loading flags
  bool _statsLoading = true;
  bool _suggestedLoading = true;
  bool _topicsLoading = true;
  bool _activityLoading = true;
  bool _featuredLoading = true;
  bool _recentVideosLoading = true;

  // Data
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _suggestedFollows = [];
  List<Map<String, dynamic>> _trendingTopics = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic>? _featuredVideo;
  List<Map<String, dynamic>> _recentVideos = [];

  // Per-user follow state keyed by user id
  final Map<dynamic, bool> _followingMap = {};

  static const _chartDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final name = await AuthService.getUserName();
    if (mounted) setState(() => _userName = name ?? 'Student');

    await Future.wait([
      _loadStats(),
      _loadSuggested(),
      _loadTopics(),
      _loadActivity(),
      _loadVideos(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await VideoService.getUserStats();
      if (mounted) setState(() { _userStats = stats; _statsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadSuggested() async {
    try {
      final users = await VideoService.getSuggestedUsers();
      if (mounted) {
        final map = <dynamic, bool>{};
        for (final u in users) {
          map[u['id']] = u['is_following'] == true;
        }
        setState(() {
          _suggestedFollows = users;
          _followingMap.addAll(map);
          _suggestedLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _suggestedLoading = false);
    }
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await VideoService.getTrendingTopics();
      if (mounted) setState(() { _trendingTopics = topics; _topicsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _topicsLoading = false);
    }
  }

  Future<void> _loadActivity() async {
    try {
      final raw = await VideoService.getNotifications();
      if (mounted) {
        setState(() {
          _recentActivity = raw.take(5).map(_normalizeActivity).toList();
          _activityLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    try {
      final trending = await VideoService.getTrending();
      if (mounted) {
        setState(() {
          _featuredVideo = trending.isNotEmpty ? trending.first : null;
          _featuredLoading = false;
          // Recent videos: feed (skip the featured one if we can)
          _recentVideos = trending.length > 1 ? trending.sublist(1, trending.length.clamp(1, 4)) : [];
          _recentVideosLoading = _recentVideos.isEmpty;
        });
      }
      // Also load feed for recent videos
      final feed = await VideoService.getFeed();
      if (mounted && feed.isNotEmpty) {
        setState(() {
          _recentVideos = feed.take(3).toList();
          _recentVideosLoading = false;
        });
      } else {
        if (mounted) setState(() => _recentVideosLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _featuredLoading = false;
          _recentVideosLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _normalizeActivity(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? 'system';
    Color dotColor;
    switch (type) {
      case 'like':
        dotColor = AppColors.error;
        break;
      case 'follow':
        dotColor = AppColors.accentLight;
        break;
      case 'comment':
        dotColor = AppColors.accent;
        break;
      default:
        dotColor = AppColors.success;
    }
    final notifier = (n['notifier'] is Map)
        ? n['notifier'] as Map<String, dynamic>
        : (n['from_user'] is Map)
            ? n['from_user'] as Map<String, dynamic>
            : <String, dynamic>{};
    final name = notifier['name'] ?? n['name'] ?? 'ReelScholar';
    final action = n['message'] ?? n['action'] ?? '';
    final target = n['target'] ?? n['video_title'] ?? '';
    final text = target.toString().isNotEmpty ? '$name $action "$target"' : '$name $action';
    return {
      'dotColor': dotColor,
      'text': text.toString(),
      'time': n['created_at']?.toString() ?? '',
    };
  }

  Future<void> _toggleFollow(dynamic userId, int index) async {
    final current = _followingMap[userId] ?? false;
    setState(() => _followingMap[userId] = !current);
    try {
      await VideoService.toggleFollow(userId);
    } catch (_) {
      if (mounted) setState(() => _followingMap[userId] = current);
    }
  }

  // Chart bars from weekly_views in stats, normalised 0.0–1.0
  List<double> _chartBars() {
    final weekly = _userStats['weekly_views'];
    if (weekly is List && weekly.isNotEmpty) {
      final maxVal = weekly
          .map((e) => (e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0))
          .reduce((a, b) => a > b ? a : b);
      if (maxVal > 0) {
        return weekly
            .map((e) => ((e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0) / maxVal)
                .clamp(0.05, 1.0))
            .toList()
            .cast<double>();
      }
    }
    return [];
  }

  // Gradient colors for suggested user avatars based on school
  (Color, Color) _userColors(String school) {
    final s = school.toLowerCase();
    if (s.contains('engineering')) return (const Color(0xFF1A3A6B), const Color(0xFF2D5FA6));
    if (s.contains('natural') || s.contains('science')) return (const Color(0xFF065F46), const Color(0xFF059669));
    if (s.contains('medicine') || s.contains('health')) return (const Color(0xFF831843), const Color(0xFFBE185D));
    if (s.contains('business')) return (const Color(0xFF92400E), const Color(0xFFD97706));
    if (s.contains('agriculture')) return (const Color(0xFF14532D), const Color(0xFF16A34A));
    if (s.contains('law')) return (const Color(0xFF1E1B4B), const Color(0xFF4F46E5));
    return (const Color(0xFF1A3A6B), const Color(0xFF2D5FA6));
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Stat card helpers ──────────────────────────────────────────
  String _statValue(String key, String fallback) {
    final v = _userStats[key];
    if (v == null) return fallback;
    if (v is int || v is double) return VideoService.formatCount(v);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final chartBars = _chartBars();

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Welcome back, ${_userName.split(' ').first}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _DashTopBtn(
                      icon: Icons.search_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DashTopBtn(
                      icon: Icons.notifications_outlined,
                      hasBadge: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats grid ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.insights_rounded, label: 'Your Stats'),
                    const SizedBox(height: 10),
                    _statsLoading
                        ? const _LoadingCard(height: 160)
                        : GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.4,
                            children: [
                              _StatCard(
                                icon: Icons.visibility_outlined,
                                value: _statValue('total_views', '—'),
                                label: 'Total Views',
                                change: _userStats['views_change']?.toString() ?? '',
                              ),
                              _StatCard(
                                icon: Icons.people_outline_rounded,
                                value: _statValue('followers_count', '—'),
                                label: 'Followers',
                                change: _userStats['followers_change']?.toString() ?? '',
                              ),
                              _StatCard(
                                icon: Icons.bar_chart_rounded,
                                value: _userStats['quiz_average'] != null
                                    ? '${_userStats['quiz_average']}%'
                                    : '—',
                                label: 'Quiz Avg.',
                                change: _userStats['quiz_change']?.toString() ?? '',
                              ),
                              _StatCard(
                                icon: Icons.video_library_outlined,
                                value: _statValue('videos_count', '—'),
                                label: 'Videos',
                                change: _userStats['videos_change']?.toString() ?? '',
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            // ── Featured today ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.star_outline_rounded, label: 'Featured Today'),
                    const SizedBox(height: 10),
                    _featuredLoading
                        ? const _LoadingCard(height: 100)
                        : _featuredVideo == null
                            ? const _EmptyCard(message: 'No featured content right now')
                            : _FeaturedCard(
                                title: _featuredVideo!['title'] as String,
                                tag: _featuredVideo!['school'] as String? ?? 'Trending',
                                meta:
                                    '${_featuredVideo!['name']}  ·  ${_featuredVideo!['likes']} likes',
                              ),
                  ],
                ),
              ),
            ),

            // ── Engagement analytics ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      icon: Icons.bar_chart_rounded,
                      label: 'Engagement Analytics — This Week',
                    ),
                    const SizedBox(height: 10),
                    _statsLoading
                        ? const _LoadingCard(height: 110)
                        : chartBars.isEmpty
                            ? const _EmptyCard(message: 'No engagement data yet')
                            : Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 80,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: List.generate(chartBars.length, (i) {
                                          final isHigh = chartBars[i] >= 0.9;
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 3),
                                              child: FractionallySizedBox(
                                                heightFactor: chartBars[i],
                                                alignment: Alignment.bottomCenter,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isHigh
                                                        ? AppColors.accent
                                                        : AppColors.accent.withValues(alpha: 0.35),
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(
                                        chartBars.length.clamp(0, _chartDays.length),
                                        (i) => Expanded(
                                          child: Text(
                                            _chartDays[i],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ],
                ),
              ),
            ),

            // ── Who to follow ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.person_add_outlined, label: 'Who to Follow'),
                    const SizedBox(height: 10),
                    _suggestedLoading
                        ? const _LoadingCard(height: 180)
                        : _suggestedFollows.isEmpty
                            ? const _EmptyCard(message: 'No suggestions right now')
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: List.generate(_suggestedFollows.length, (i) {
                                    final f = _suggestedFollows[i];
                                    final uid = f['id'];
                                    final isFollowing = _followingMap[uid] ?? false;
                                    final school = f['school']?.toString() ?? f['department']?.toString() ?? '';
                                    final videosCount = f['videos_count'] ?? f['video_count'] ?? 0;
                                    final (colorA, colorB) = _userColors(school);
                                    return _FollowItem(
                                      initials: _initials(f['name']?.toString() ?? '?'),
                                      name: f['name']?.toString() ?? 'Unknown',
                                      role: '$school · $videosCount videos',
                                      colorA: colorA,
                                      colorB: colorB,
                                      isFollowing: isFollowing,
                                      isLast: i == _suggestedFollows.length - 1,
                                      onToggle: () => _toggleFollow(uid, i),
                                    );
                                  }),
                                ),
                              ),
                  ],
                ),
              ),
            ),

            // ── Trending topics ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      icon: Icons.trending_up_rounded,
                      label: 'Trending Topics',
                    ),
                    const SizedBox(height: 10),
                    _topicsLoading
                        ? const _LoadingCard(height: 140)
                        : _trendingTopics.isEmpty
                            ? const _EmptyCard(message: 'No trending topics yet')
                            : Container(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: List.generate(_trendingTopics.length, (i) {
                                    final t = _trendingTopics[i];
                                    final tag = t['tag']?.toString() ??
                                        t['name']?.toString() ??
                                        '#Topic';
                                    final pct = (t['percentage'] is num
                                            ? (t['percentage'] as num).toDouble()
                                            : double.tryParse(
                                                    t['percentage']?.toString() ?? '') ??
                                                ((t['count'] is num
                                                        ? (t['count'] as num).toDouble()
                                                        : 1.0) /
                                                    (_trendingTopics.first['count'] is num
                                                        ? (_trendingTopics.first['count'] as num).toDouble()
                                                        : 1.0)))
                                        .clamp(0.05, 1.0);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            child: Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: i < 2
                                                    ? AppColors.warning
                                                    : AppColors.textTertiary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tag,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            width: 80,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 4,
                                                backgroundColor: AppColors.border,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                  ],
                ),
              ),
            ),

            // ── Recent activity ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(icon: Icons.bolt_rounded, label: 'Recent Activity'),
                    const SizedBox(height: 10),
                    _activityLoading
                        ? const _LoadingCard(height: 120)
                        : _recentActivity.isEmpty
                            ? const _EmptyCard(message: 'No recent activity')
                            : Container(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: List.generate(_recentActivity.length, (i) {
                                    final a = _recentActivity[i];
                                    final dotColor = a['dotColor'] as Color;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: dotColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              a['text'] as String,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            a['time'] as String,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                  ],
                ),
              ),
            ),

            // ── Recent videos ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      icon: Icons.video_library_outlined,
                      label: 'Recent Videos',
                    ),
                    const SizedBox(height: 10),
                    _recentVideosLoading
                        ? const _LoadingCard(height: 160)
                        : _recentVideos.isEmpty
                            ? const _EmptyCard(message: 'No videos yet')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentVideos.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.72,
                                ),
                                itemBuilder: (_, i) {
                                  final v = _recentVideos[i];
                                  return _VideoMiniCard(
                                    title: v['title'] as String,
                                    subject: v['subject'] as String? ?? '',
                                    likes: v['likes'] as String? ?? '0',
                                    colorA: v['color'] as Color,
                                    colorB: v['accent'] as Color,
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared placeholder widgets ──────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DashTopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _DashTopBtn({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 18, color: AppColors.textSecondary)),
            if (hasBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String change;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          if (change.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              change,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String tag;
  final String meta;

  const _FeaturedCard({
    required this.title,
    required this.tag,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2347), Color(0xFF2D5FA6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 10,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trending in $tag',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5A623),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 11,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meta,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF0D2347),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowItem extends StatelessWidget {
  final String initials;
  final String name;
  final String role;
  final Color colorA;
  final Color colorB;
  final bool isFollowing;
  final bool isLast;
  final VoidCallback onToggle;

  const _FollowItem({
    required this.initials,
    required this.name,
    required this.role,
    required this.colorA,
    required this.colorB,
    required this.isFollowing,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorA, colorB],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isFollowing ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFollowing ? AppColors.accent : AppColors.borderMid,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _VideoMiniCard extends StatelessWidget {
  final String title;
  final String subject;
  final String likes;
  final Color colorA;
  final Color colorB;

  const _VideoMiniCard({
    required this.title,
    required this.subject,
    required this.likes,
    required this.colorA,
    required this.colorB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 28,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subject.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 9,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        likes,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
