import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../models/video_store.dart';
import '../widgets/video_player_widget.dart';
import 'login_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _userName = 'Student';
  String _userEmail = '';
  String _bio = '';
  String? _profileImagePath;
  bool _isLoading = true;

  int _videosCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  int _likesCount = 0;

  List<Map<String, dynamic>> _myApiVideos = [];
  bool _myVideosLoading = true;

  List<Map<String, dynamic>> _likedVideos = [];
  bool _likedLoading = true;

  List<Map<String, dynamic>> _achievements = [];
  bool _achievementsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadMyVideos();
    _loadLikedVideos();
    _loadAchievements();
  }

  Future<void> _loadUserData() async {
    final email = await AuthService.getUserEmail();
    final name = await AuthService.getUserName();
    final bio = await AuthService.getBio();
    final imgPath = await AuthService.getProfileImagePath();

    // Try loading real stats from API
    Map<String, dynamic> profile = {};
    try {
      profile = await VideoService.getUserProfile();
    } catch (_) {}

    final myVideos =
        VideoStore.videos.where((v) => v['username'] == '@me').toList();

    if (mounted) {
      setState(() {
        _userEmail = email ?? '';
        _userName = profile['name']?.toString() ?? name ?? 'Student';
        _bio = profile['bio']?.toString() ?? bio ?? '';
        _profileImagePath = imgPath;
        _videosCount =
            (profile['videos_count'] ?? profile['video_count'] ?? myVideos.length) is int
                ? profile['videos_count'] ?? profile['video_count'] ?? myVideos.length
                : int.tryParse(
                        (profile['videos_count'] ?? profile['video_count'] ?? myVideos.length).toString()) ??
                    myVideos.length;
        _followersCount = _parseCount(profile['followers_count'] ?? profile['followers'] ?? 0);
        _followingCount = _parseCount(profile['following_count'] ?? profile['following'] ?? 0);
        _likesCount = _parseCount(profile['likes_count'] ?? profile['likes'] ?? 0);
        _isLoading = false;
      });
    }
  }

  int _parseCount(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _loadMyVideos() async {
    try {
      final list = await VideoService.getMyVideos();
      if (mounted) setState(() { _myApiVideos = list; _myVideosLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _myVideosLoading = false);
    }
  }

  Future<void> _loadLikedVideos() async {
    try {
      final list = await VideoService.getLikedVideos();
      if (mounted) setState(() { _likedVideos = list; _likedLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _likedLoading = false);
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final list = await VideoService.getAchievements();
      if (mounted) setState(() { _achievements = list; _achievementsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _achievementsLoading = false);
    }
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        currentName: _userName,
        currentBio: _bio,
        currentImagePath: _profileImagePath,
        onSaved: (name, bio, imagePath) {
          setState(() {
            _userName = name;
            _bio = bio;
            _profileImagePath = imagePath;
          });
        },
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of ReelScholar?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await VideoService.logoutFromServer();
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => const LoginScreen(),
                    transitionsBuilder: (_, anim, _, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                  (_) => false,
                );
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Merge local (just-uploaded) videos with API videos, deduplicated by title
    final localVideos = VideoStore.videos.where((v) => v['username'] == '@me').toList();
    final apiTitles   = _myApiVideos.map((v) => v['title']).toSet();
    final localOnly   = localVideos.where((v) => !apiTitles.contains(v['title'])).toList();
    final myVideos    = [...localOnly, ..._myApiVideos];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                SliverAppBar(
                  backgroundColor: AppColors.bg,
                  expandedHeight: _bio.isNotEmpty ? 460 : 430,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      onPressed: _handleLogout,
                      icon: Icon(
                        Icons.logout_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      tooltip: 'Log out',
                    ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: ClipRect(child: _buildProfileHeader(myVideos)),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 2,
                    dividerColor: AppColors.border,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textTertiary,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'My Videos'),
                      Tab(text: 'Liked'),
                      Tab(text: 'Achievements'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyVideosTab(myVideos),
                  _buildLikedTab(_likedVideos),
                  _buildAchievementsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(List<Map<String, dynamic>> myVideos) {
    final hasPhoto =
        _profileImagePath != null && File(_profileImagePath!).existsSync();

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Avatar
            Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.file(
                            File(_profileImagePath!),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(_userName, style: AppTextStyles.headingLarge),
            const SizedBox(height: 3),
            Text(
              _userEmail,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),

            // Bio
            if (_bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'CUT STUDENT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Stats row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(_videosCount.toString(), 'Videos'),
                  _buildStatDivider(),
                  _buildStat(_followersCount.toString(), 'Followers'),
                  _buildStatDivider(),
                  _buildStat(_followingCount.toString(), 'Following'),
                  _buildStatDivider(),
                  _buildStat(_likesCount.toString(), 'Likes'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.borderMid),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 28, color: AppColors.border);

  Widget _buildMyVideosTab(List<Map<String, dynamic>> myVideos) {
    if (_myVideosLoading && myVideos.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (myVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No videos yet', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text('Upload your first educational video', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Upload Video'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: myVideos.length,
      itemBuilder: (context, index) {
        final video = myVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _VideoPlayerScreen(video: video),
              ),
            );
          },
          child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.accent.withValues(alpha: 0.5),
                  size: 40,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(10)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.bg.withValues(alpha: 0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.favorite_outline_rounded,
                              size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            video['likes'] ?? '0',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textMuted,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video['subject'] ?? '',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildLikedTab(List<Map<String, dynamic>> likedVideos) {
    if (_likedLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (likedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No liked videos yet', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text('Videos you like will appear here', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: likedVideos.length,
      itemBuilder: (context, index) {
        final video = likedVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _VideoPlayerScreen(video: video),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.accent.withValues(alpha: 0.5),
                    size: 40,
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.bg.withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.favorite_rounded,
                                size: 10, color: AppColors.error),
                            const SizedBox(width: 3),
                            Text(
                              video['likes'] ?? '0',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video['subject'] ?? '',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Map an icon name string from the API to a Flutter IconData.
  static IconData _resolveIcon(String? name) {
    switch (name?.toLowerCase()) {
      case 'star':          return Icons.star_rounded;
      case 'fire':          return Icons.local_fire_department_rounded;
      case 'school':        return Icons.school_rounded;
      case 'people':        return Icons.people_rounded;
      case 'trophy':
      case 'hackathon':     return Icons.emoji_events_rounded;
      case 'video':         return Icons.video_library_rounded;
      case 'chat':
      case 'comment':       return Icons.chat_rounded;
      case 'share':         return Icons.share_rounded;
      case 'medal':         return Icons.military_tech_rounded;
      case 'quiz':          return Icons.quiz_rounded;
      case 'like':          return Icons.favorite_rounded;
      default:              return Icons.emoji_events_rounded;
    }
  }

  /// Parse a color from the API (hex string like "#F59E0B" or int).
  static Color _resolveColor(dynamic raw) {
    if (raw == null) return const Color(0xFFF59E0B);
    if (raw is int) return Color(raw);
    final hex = raw.toString().replaceAll('#', '');
    if (hex.length == 6) return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFFF59E0B);
    if (hex.length == 8) return Color(int.tryParse(hex, radix: 16) ?? 0xFFF59E0B);
    return const Color(0xFFF59E0B);
  }

  Widget _buildAchievementsTab() {
    if (_achievementsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No achievements yet', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text(
              'Upload videos, complete quizzes\nand engage with the community',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    final unlocked = _achievements.where((a) => a['unlocked'] == true || a['is_unlocked'] == true).toList();
    final locked = _achievements.where((a) => a['unlocked'] != true && a['is_unlocked'] != true).toList();
    final total = _achievements.length;
    final pct = total > 0 ? ((unlocked.length / total) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          Container(
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.military_tech_rounded,
                      color: Color(0xFFF5A623), size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Achievements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${unlocked.length} of $total unlocked',
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ],
            ),
          ),

          if (unlocked.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('UNLOCKED'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: unlocked.map((a) => _AchievementCard(
                icon: _resolveIcon(a['icon']?.toString()),
                label: a['name']?.toString() ?? a['label']?.toString() ?? '',
                desc: a['description']?.toString() ?? a['desc']?.toString() ?? '',
                color: _resolveColor(a['color']),
                unlocked: true,
              )).toList(),
            ),
          ],

          if (locked.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('LOCKED'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: locked.map((a) => _AchievementCard(
                icon: _resolveIcon(a['icon']?.toString()),
                label: a['name']?.toString() ?? a['label']?.toString() ?? '',
                desc: a['description']?.toString() ?? a['desc']?.toString() ?? '',
                color: _resolveColor(a['color']),
                unlocked: false,
              )).toList(),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      );
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String? currentImagePath;
  final void Function(String name, String bio, String? imagePath) onSaved;

  const _EditProfileSheet({
    required this.currentName,
    required this.currentBio,
    required this.currentImagePath,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _bioController = TextEditingController(text: widget.currentBio);
    _selectedImagePath = widget.currentImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImagePath = picked.path);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImagePath != null)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedImagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name cannot be empty'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final bio = _bioController.text.trim();

    // Save locally first (works offline)
    await AuthService.saveBio(bio);
    if (_selectedImagePath != null) {
      await AuthService.saveProfileImagePath(_selectedImagePath!);
    } else {
      await AuthService.clearProfileImagePath();
    }

    // Try to sync with API (non-blocking — fail silently)
    try {
      await VideoService.updateProfile(
        name: name,
        bio: bio,
        avatar: _selectedImagePath != null ? File(_selectedImagePath!) : null,
      );
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onSaved(name, bio, _selectedImagePath);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        _selectedImagePath != null && File(_selectedImagePath!).existsSync();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.borderMid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textTertiary, size: 20),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar picker
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                              border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                  width: 3),
                            ),
                            child: ClipOval(
                              child: hasPhoto
                                  ? Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 46,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.bg, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Tap to change photo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Name
                  _fieldLabel('Full Name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your full name',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 14),
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.textTertiary, size: 18),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _fieldLabel('Biography'),
                      ValueListenableBuilder(
                        valueListenable: _bioController,
                        builder: (_, val, _) => Text(
                          '${val.text.length}/200',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: val.text.length > 180
                                ? AppColors.warning
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 200,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tell others about yourself — your school, interests, research...',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          height: 1.5),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}

// ─── Achievement Card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final bool unlocked;

  const _AchievementCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? color.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked
                  ? color.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? color : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: AppColors.textTertiary,
                    height: 1.3,
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

class _VideoPlayerScreen extends StatelessWidget {
  final Map<String, dynamic> video;

  const _VideoPlayerScreen({required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          video['title'] ?? '',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
      ),
      body: Center(
        child: video['filePath'] != null
            ? VideoPlayerWidget(filePath: video['filePath'] as String)
            : video['networkUrl'] != null
                ? VideoPlayerWidget(networkUrl: video['networkUrl'] as String)
                : const Text(
                    'Video unavailable',
                    style: TextStyle(color: Colors.white54),
                  ),
      ),
    );
  }
}
