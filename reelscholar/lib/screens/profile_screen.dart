import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/video_store.dart';
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
  bool _isLoading = true;

  int _videosCount = 0;
  final int _followersCount = 0;
  final int _followingCount = 0;
  final int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await AuthService.getUserEmail();
    final name = await AuthService.getUserName();
    final myVideos =
        VideoStore.videos.where((v) => v['username'] == '@me').toList();

    setState(() {
      _userEmail = email ?? '';
      _userName = name ?? 'Student';
      _videosCount = myVideos.length;
      _isLoading = false;
    });
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
    final myVideos =
        VideoStore.videos.where((v) => v['username'] == '@me').toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                SliverAppBar(
                  backgroundColor: AppColors.bg,
                  expandedHeight: 330,
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
                    background: _buildProfileHeader(myVideos),
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
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyVideosTab(myVideos),
                  _buildLikedTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(List<Map<String, dynamic>> myVideos) {
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _userName,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 3),
            Text(
              _userEmail,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            const SizedBox(height: 20),

            // Stats row
            Container(
              margin: EdgeInsets.symmetric(horizontal: 28),
              padding: EdgeInsets.symmetric(vertical: 14),
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
              onPressed: () {},
              icon: Icon(Icons.edit_outlined, size: 14),
              label: Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.borderMid),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
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

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  Widget _buildMyVideosTab(List<Map<String, dynamic>> myVideos) {
    if (myVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('No videos yet', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text(
              'Upload your first educational video',
              style: AppTextStyles.bodyMedium,
            ),
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
        return Container(
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
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
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
                          Icon(
                            Icons.favorite_outline_rounded,
                            size: 10,
                            color: AppColors.textMuted,
                          ),
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
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
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
        );
      },
    );
  }

  Widget _buildLikedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline_rounded,
            size: 52,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text('No liked videos yet', style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text(
            'Videos you like will appear here',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

