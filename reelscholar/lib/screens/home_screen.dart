import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search_screen.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'alerts_screen.dart';
import 'messages_screen.dart';
import 'dashboard_screen.dart';
import 'hackathon_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/share_sheet.dart';
import '../models/video_store.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/quiz_popup.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../services/api_constants.dart';
import '../main.dart';
import 'login_screen.dart';

// ─── Design tokens (matching the blue-theme image) ───────────────────────────

const _kNavBg     = Color(0xFF0A1628);   // very dark navy – page background
const _kTopBar    = Color(0xFF1A3D7C);   // deep blue – top bar + profile row
const _kTabRow    = Color(0xFF142F62);   // slightly deeper – tab row bg
const _kOrange    = Color(0xFFF5A623);   // orange – play button & tab indicator
const _kCardBg    = Color(0xFF0F2040);   // card background
const _kFollowBtn = Color(0xFF1A3D7C);   // follow button bg
const _kDivider   = Color(0xFF1E3A6E);   // subtle divider

// ─── HomeScreen (landing page with bottom nav) ───────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _tab = 0; // 0=Home, 1=Quiz, 2=Hackathon, 3=Messages, 4=Profile
  int _feedTab = 0; // 0=For You, 1=Following, 2=My Faculty

  Map<String, dynamic>? _featuredVideo;
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _loadingFeatured = true;
  bool _loadingSuggested = true;
  String _userName = 'ReelScholar';
  String _userInitials = 'RS';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadUserInfo();
    _loadFeatured();
    _loadSuggested();
  }

  void _loadUserInfo() async {
    final name = await AuthService.getUserName() ?? 'ReelScholar';
    if (mounted) {
      setState(() {
        _userName = name;
        final parts = name.trim().split(' ');
        _userInitials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
      });
    }
  }

  void _loadFeatured() async {
    setState(() => _loadingFeatured = true);
    try {
      final filter = switch (_feedTab) {
        1 => 'following',
        2 => 'my_school',
        _ => 'for_you',
      };
      final dept = await AuthService.getDepartment();
      final videos = await VideoService.getFeed(
        filter: filter,
        school: _feedTab == 2 ? dept : null,
      );
      if (mounted) {
        setState(() {
          _featuredVideo = videos.isNotEmpty ? videos.first : null;
          _loadingFeatured = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  void _loadSuggested() async {
    setState(() => _loadingSuggested = true);
    try {
      final users = await VideoService.getSuggestedUsers();
      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _loadingSuggested = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuggested = false);
    }
  }

  void _onFeedTabChanged(int i) {
    setState(() => _feedTab = i);
    _loadFeatured();
  }

  void _openVideoFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoFeedScreen(initialFeedTab: _feedTab)),
    );
  }

  // ─── body per bottom-nav tab ─────────────────────────────────────────────

  Widget _buildBody() {
    switch (_tab) {
      case 1:
        return _QuizTabBody(onShowQuiz: _showSubjectPicker);
      case 2:
        return const HackathonScreen(embedded: true);
      case 3:
        return const MessagesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _HomeTabBody(
          userName: _userName,
          userInitials: _userInitials,
          feedTab: _feedTab,
          featuredVideo: _featuredVideo,
          suggestedUsers: _suggestedUsers,
          loadingFeatured: _loadingFeatured,
          loadingSuggested: _loadingSuggested,
          onFeedTabChanged: _onFeedTabChanged,
          onTapFeatured: _openVideoFeed,
          onRefreshSuggested: _loadSuggested,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onUpload: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            );
            _loadFeatured();
          },
          onSearch: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          onAlerts: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ),
        );
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kNavBg,
      drawer: _AppDrawer(
        userName: _userName,
        userInitials: _userInitials,
        onNavigate: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          setState(() => _tab = i);
        },
      ),
      body: _buildBody(),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }

  // ─── Quiz subject picker ──────────────────────────────────────────────────

  void _showSubjectPicker(BuildContext context) async {
    final faculty = await AuthService.getDepartment();
    final semester = await AuthService.getSemester();
    if (!context.mounted) return;

    // Show bottom sheet with a loading state while fetching modules from API
    List<String> modules = [];
    bool loadingModules = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Fetch on first render
          if (loadingModules) {
            Future.microtask(() async {
              try {
                final uri = Uri.parse('$kLaravelUrl/api/meta/modules').replace(
                  queryParameters: {
                    'faculty': faculty ?? '',
                    'semester': semester.toString(),
                  },
                );
                final res = await http.get(uri, headers: {'Accept': 'application/json'});
                if (res.statusCode == 200) {
                  final body = json.decode(res.body);
                  final raw = body['modules'] ?? body['data'];
                  if (raw is List && raw.isNotEmpty) {
                    modules = raw.map((e) => e.toString()).toList();
                  }
                }
              } catch (_) {}
              if (ctx.mounted) {
                setSheetState(() => loadingModules = false);
              }
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, sc) => Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semester $semester Modules',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        if (faculty != null && faculty.isNotEmpty)
                          Text(faculty,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: AppColors.textTertiary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: loadingModules
                        ? const Center(child: CircularProgressIndicator())
                        : modules.isEmpty
                            ? Center(
                                child: Text(
                                  'No modules found',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: sc,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: modules.length,
                                itemBuilder: (c, i) {
                                  final subject = modules[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.pop(c);
                                        showQuiz(context, subject, subject);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.menu_book_outlined, color: AppColors.accentLight, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(subject,
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                                                  fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                            ),
                                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, sc) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semester $semester Modules',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          if (faculty != null && faculty.isNotEmpty)
                            Text(faculty,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                color: AppColors.textTertiary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: modules.length,
                  itemBuilder: (c, i) {
                    final subject = modules[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(c);
                          showQuiz(context, subject, subject);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_outlined, color: AppColors.accentLight, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(subject,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                                    fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String userName;
  final String userInitials;
  final ValueChanged<int> onNavigate;

  const _AppDrawer({
    required this.userName,
    required this.userInitials,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A1628),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: const Color(0xFF1A3D7C),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Nav items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => onNavigate(0),
            ),
            _DrawerItem(
              icon: Icons.quiz_rounded,
              label: 'Quiz',
              onTap: () => onNavigate(1),
            ),
            _DrawerItem(
              icon: Icons.emoji_events_rounded,
              label: 'Hackathon',
              onTap: () => onNavigate(2),
            ),
            _DrawerItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Messages',
              onTap: () => onNavigate(3),
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: () => onNavigate(4),
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'Search',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
              },
            ),

            const Spacer(),

            const Divider(color: Color(0xFF1E3A6E)),

            // Logout
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 4,
    );
  }
}

// ─── Home tab body ────────────────────────────────────────────────────────────

class _HomeTabBody extends StatelessWidget {
  final String userName;
  final String userInitials;
  final int feedTab;
  final Map<String, dynamic>? featuredVideo;
  final List<Map<String, dynamic>> suggestedUsers;
  final bool loadingFeatured;
  final bool loadingSuggested;
  final ValueChanged<int> onFeedTabChanged;
  final VoidCallback onTapFeatured;
  final VoidCallback onRefreshSuggested;
  final VoidCallback onUpload;
  final VoidCallback onSearch;
  final VoidCallback onAlerts;
  final VoidCallback onMenuTap;

  const _HomeTabBody({
    required this.userName,
    required this.userInitials,
    required this.feedTab,
    required this.featuredVideo,
    required this.suggestedUsers,
    required this.loadingFeatured,
    required this.loadingSuggested,
    required this.onFeedTabChanged,
    required this.onTapFeatured,
    required this.onRefreshSuggested,
    required this.onMenuTap,
    required this.onUpload,
    required this.onSearch,
    required this.onAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Fixed blue header ──────────────────────────────────────────────
        Container(
          color: _kTopBar,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      // Hamburger – opens drawer
                      GestureDetector(
                        onTap: onMenuTap,
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Logo
                      Expanded(
                        child: Text(
                          'ReelScholar',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Search
                      _HeaderIcon(
                        icon: Icons.search_rounded,
                        onTap: onSearch,
                      ),
                      const SizedBox(width: 8),
                      // Alerts with badge
                      _HeaderIcon(
                        icon: Icons.notifications_outlined,
                        hasBadge: true,
                        onTap: onAlerts,
                      ),
                      const SizedBox(width: 8),
                      // Dashboard/stats
                      _HeaderIcon(
                        icon: Icons.compass_calibration_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // Profile row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: _kOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userInitials,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Upload / add button
                      GestureDetector(
                        onTap: onUpload,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Feed tabs
                _FeedTabRow(selectedIndex: feedTab, onChanged: onFeedTabChanged),
              ],
            ),
          ),
        ),

        // ── Scrollable content ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Featured Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Featured Content',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FeaturedCard(
                    video: featuredVideo,
                    loading: loadingFeatured,
                    onTap: onTapFeatured,
                  ),
                ),

                const SizedBox(height: 24),

                // Suggested to Follow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Suggested to Follow',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kOrange,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRefreshSuggested,
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A9EF5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _SuggestedSection(
                  users: suggestedUsers,
                  loading: loadingSuggested,
                ),

                const SizedBox(height: 24),

                // Quick links grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Access',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _QuickLinksGrid(onTapFeed: onTapFeatured),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Feed tab row (For You | Following | My Faculty) ─────────────────────────

class _FeedTabRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FeedTabRow({required this.selectedIndex, required this.onChanged});

  static const _tabs = ['For You', 'Following', 'My Faculty'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kTabRow,
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? _kOrange : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Header icon button ───────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          if (hasBadge)
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Featured Content Card ────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic>? video;
  final bool loading;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.video,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 200,
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A1628),
                      Colors.black,
                    ],
                  ),
                ),
              ),

              if (loading)
                const Center(
                  child: CircularProgressIndicator(
                    color: _kOrange, strokeWidth: 2,
                  ),
                )
              else ...[
                // Orange play button (centre)
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: const BoxDecoration(
                      color: _kOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                // Bottom info overlay
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: video != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                video!['title']?.toString().isNotEmpty == true
                                    ? video!['title']
                                    : 'Start watching now',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    video!['name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${video!['likes'] ?? '0'} likes',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Text(
                            'Tap to enter the video feed',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Suggested to Follow – HORIZONTAL scroll ──────────────────────────────────

class _SuggestedSection extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;

  const _SuggestedSection({required this.users, required this.loading});

  // Demo users shown when API returns nothing
  static const _demo = [
    {'name': 'Engineering Sciences', 'followers': '1,200', 'videos': '28'},
    {'name': 'Natural Sciences',     'followers': '847',   'videos': '15'},
    {'name': 'Medicine & Health',    'followers': '2,100', 'videos': '41'},
    {'name': 'Business Sciences',    'followers': '563',   'videos': '9'},
    {'name': 'Wildlife & Env.',      'followers': '730',   'videos': '22'},
  ];

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2),
        ),
      );
    }

    final items = users.isNotEmpty
        ? users
        : _demo.map((d) => Map<String, dynamic>.from(d)).toList();

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final user = items[i];
          return _SuggestedUserCard(user: user, index: i);
        },
      ),
    );
  }
}

class _SuggestedUserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final int index;

  const _SuggestedUserCard({required this.user, required this.index});

  @override
  State<_SuggestedUserCard> createState() => _SuggestedUserCardState();
}

class _SuggestedUserCardState extends State<_SuggestedUserCard> {
  bool _following = false;

  void _toggle() {
    setState(() => _following = !_following);
    final userId = widget.user['id'];
    if (userId != null) {
      VideoService.toggleFollow(userId).catchError((_) {
        if (mounted) setState(() => _following = !_following);
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static const _colors = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A),
    Color(0xFF00838F), Color(0xFFE65100),
  ];

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = user['name']?.toString() ?? user['username']?.toString() ?? 'User';
    final followers = user['followers_count']?.toString() ??
        user['followers']?.toString() ?? '—';
    final avatarColor = _colors[widget.index % _colors.length];

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor.withValues(alpha: 0.2),
            child: Text(
              _initials(name),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          // Followers · Videos
          Text(
            '$followers followers',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF4A9EF5),
            ),
          ),
          const SizedBox(height: 6),
          // Follow button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _following
                    ? Colors.white.withValues(alpha: 0.12)
                    : _kFollowBtn,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _following
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF4A9EF5),
                ),
              ),
              child: Text(
                _following ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Links Grid ─────────────────────────────────────────────────────────

class _QuickLinksGrid extends StatelessWidget {
  final VoidCallback onTapFeed;
  const _QuickLinksGrid({required this.onTapFeed});

  @override
  Widget build(BuildContext context) {
    final links = [
      _QLinkItem(Icons.play_circle_outline_rounded, 'Video Feed', onTapFeed),
      _QLinkItem(Icons.search_rounded, 'Discover', () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
      _QLinkItem(Icons.emoji_events_outlined, 'Hackathon', () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HackathonScreen()))),
      _QLinkItem(Icons.dashboard_outlined, 'Dashboard', () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: links.map((l) => _QuickLinkCard(item: l)).toList(),
    );
  }
}

class _QLinkItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QLinkItem(this.icon, this.label, this.onTap);
}

class _QuickLinkCard extends StatelessWidget {
  final _QLinkItem item;
  const _QuickLinkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: const Color(0xFF4A9EF5), size: 20),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
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

// ─── Quiz tab body ────────────────────────────────────────────────────────────

class _QuizTabBody extends StatelessWidget {
  final void Function(BuildContext) onShowQuiz;
  const _QuizTabBody({required this.onShowQuiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavBg,
      appBar: AppBar(
        backgroundColor: _kTopBar,
        elevation: 0,
        title: const Text(
          'Quiz',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              color: Colors.white, fontSize: 17),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kDivider),
                ),
                child: const Icon(Icons.quiz_outlined,
                    color: Color(0xFF4A9EF5), size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Test Your Knowledge',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a module and challenge yourself with AI-generated questions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                    color: Color(0xFF7A9CC0), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => onShowQuiz(context),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Choose a Module'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.quiz_outlined),
        activeIcon: Icon(Icons.quiz_rounded),
        label: 'Quiz',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events_outlined),
        activeIcon: Icon(Icons.emoji_events_rounded),
        label: 'Hackathon',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        activeIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0D1422),
      selectedItemColor: const Color(0xFF4A9EF5),
      unselectedItemColor: const Color(0xFF4A6080),
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
      elevation: 12,
      items: items,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO FEED SCREEN  (full-screen TikTok-style – accessed from Featured Content)
// ─────────────────────────────────────────────────────────────────────────────

class VideoFeedScreen extends StatefulWidget {
  final int initialFeedTab;
  const VideoFeedScreen({super.key, this.initialFeedTab = 0});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _videos = [];
  late int _selectedFeedTab;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFeedTab = widget.initialFeedTab;
    _loadVideos();
  }

  void _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final dept = await AuthService.getDepartment();
      final filter = switch (_selectedFeedTab) {
        1 => 'following',
        2 => 'my_school',
        _ => 'for_you',
      };
      final apiVideos = await VideoService.getFeed(
        filter: filter,
        school: _selectedFeedTab == 2 ? dept : null,
      );
      final local = VideoStore.videos.map((v) => {
        ...v,
        'color': v['color'] is Color ? v['color'] : Color(v['color'] as int),
        'accent': v['accent'] is Color ? v['accent'] : Color(v['accent'] as int),
      }).toList();
      if (mounted) {
        setState(() {
          _videos = [...local, ...apiVideos];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video feed
          if (_isLoading && _videos.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_videos.isEmpty)
            const Center(
              child: Text(
                'No videos yet',
                style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              itemBuilder: (context, index) => _VideoCard(video: _videos[index]),
            ),

          // Top bar
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Reel',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Scholar',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 18, fontWeight: FontWeight.w300,
                                    color: AppColors.accentLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _TopBarButton(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SearchScreen())),
                        icon: Icons.search_rounded,
                      ),
                    ],
                  ),
                ),
                _FeedTabSwitcher(
                  selectedIndex: _selectedFeedTab,
                  onChanged: (i) {
                    setState(() => _selectedFeedTab = i);
                    _loadVideos();
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Floating upload button
          Positioned(
            bottom: 28, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadScreen()),
                  );
                  _loadVideos();
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 18, spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video Card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late bool _isFollowing;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.video['isLiked'] == true;
    _isFollowing = widget.video['isFollowing'] == true;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() => _isLiked = !_isLiked);
    _heartController.forward().then((_) => _heartController.reverse());
    final videoId = widget.video['id'];
    if (videoId != null) {
      VideoService.toggleLike(videoId).catchError((_) {
        if (mounted) setState(() => _isLiked = !_isLiked);
      });
    }
  }

  void _handleFollow() {
    final userId = widget.video['userId'];
    if (userId == null) return;
    setState(() => _isFollowing = !_isFollowing);
    VideoService.toggleFollow(userId).catchError((_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    });
  }

  void _openUserProfile() {
    final userId = widget.video['userId'];
    final name = widget.video['name']?.toString() ?? '';
    final username = widget.video['username']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          displayName: name,
          username: username,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accent, Map<String, dynamic> video) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
                border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(Icons.play_arrow_rounded, color: accent, size: 52),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                video['subject'] ?? '',
                style: TextStyle(color: accent, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final Color accent = video['accent'] as Color;
    final Color bgColor = video['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, Colors.black],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned.fill(
            child: (video['filePath'] != null)
                ? VideoPlayerWidget(filePath: video['filePath'] as String)
                : (video['networkUrl'] != null)
                    ? VideoPlayerWidget(networkUrl: video['networkUrl'] as String)
                    : (video['fileBytes'] != null)
                        ? VideoPlayerWidget(fileBytes: video['fileBytes'] as List<int>)
                        : _buildPlaceholder(accent, video),
          ),
          // Bottom overlay
          Positioned(
            bottom: 80, left: 16, right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openUserProfile,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: accent.withValues(alpha: 0.3),
                        child: Text(
                          video['name'].toString().substring(0, 1),
                          style: TextStyle(color: accent,
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: GestureDetector(
                        onTap: _openUserProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video['name'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(video['username'],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _handleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(fontFamily: 'Poppins',
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(video['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w500, height: 1.4)),
              ],
            ),
          ),
          // Right side actions
          Positioned(
            right: 12, bottom: 100,
            child: Column(
              children: [
                _ActionButton(
                  onTap: _handleLike,
                  label: video['likes'],
                  child: AnimatedBuilder(
                    animation: _heartController,
                    builder: (_, _) => Transform.scale(
                      scale: _heartScale.value,
                      child: Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isLiked ? Colors.redAccent : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  onTap: () => showComments(context, video['title'],
                      videoId: video['id']),
                  label: video['comments'],
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  onTap: () => showShareSheet(
                      context, video['title'], video['username']),
                  label: video['shares'],
                  child: const Icon(Icons.reply_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => showQuiz(
                    context,
                    video['subject'] as String,
                    video['title'] as String,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.quiz_outlined,
                            color: AppColors.accentLight, size: 20),
                      ),
                      const SizedBox(height: 4),
                      const Text('Quiz',
                        style: TextStyle(fontFamily: 'Poppins',
                            color: Colors.white60, fontSize: 10,
                            fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String label;

  const _ActionButton({
    required this.onTap,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(label,
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Top Bar Button (used in video feed screen) ───────────────────────────────

class _TopBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _TopBarButton({
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 19)),
      ),
    );
  }
}

// ─── Feed Tab Switcher (used inside video feed screen) ───────────────────────

class _FeedTabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FeedTabSwitcher({
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _tabs = ['For You', 'Following', 'My School'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_tabs.length, (i) {
            final isSelected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
