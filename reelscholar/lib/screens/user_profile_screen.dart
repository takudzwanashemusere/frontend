import 'package:flutter/material.dart';
import '../main.dart';
import '../services/video_service.dart';
import '../widgets/video_player_widget.dart';
import 'user_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final dynamic userId;
  final String displayName;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        VideoService.getUserPublicProfile(widget.userId),
        VideoService.getUserVideos(widget.userId),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final videos = results[1] as List<Map<String, dynamic>>;
      if (mounted) {
        setState(() {
          _profile = profile;
          _videos = videos;
          _isFollowing = profile['is_following'] == true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null || _isFollowLoading) return;
    setState(() => _isFollowLoading = true);
    final prev = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    try {
      await VideoService.toggleFollow(widget.userId);
    } catch (_) {
      if (mounted) setState(() => _isFollowing = prev);
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _count(String key) {
    final v = _profile[key] ?? _profile['${key}_count'] ?? 0;
    return VideoService.formatCount(v);
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile['name']?.toString() ?? widget.displayName;
    final username = _profile['username'] != null
        ? '@${_profile['username']}'
        : widget.username;
    final school = _profile['school']?.toString() ??
        _profile['department']?.toString() ??
        '';
    final accent = VideoService.schoolAccentColor(school);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          username,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.2),
                              border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _initials(name),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Name
                          Text(name, style: AppTextStyles.headingLarge),
                          const SizedBox(height: 2),
                          Text(
                            username,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),

                          // School badge
                          if (school.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: accent.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(VideoService.schoolIcon(school), size: 13, color: accent),
                                  const SizedBox(width: 5),
                                  Text(
                                    school,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatColumn(label: 'Videos', value: _count('videos')),
                              _Divider(),
                              GestureDetector(
                                onTap: widget.userId != null
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserListScreen(
                                              userId: widget.userId,
                                              type: UserListType.followers,
                                              ownerName: name,
                                            ),
                                          ),
                                        )
                                    : null,
                                child: _StatColumn(label: 'Followers', value: _count('followers')),
                              ),
                              _Divider(),
                              GestureDetector(
                                onTap: widget.userId != null
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserListScreen(
                                              userId: widget.userId,
                                              type: UserListType.following,
                                              ownerName: name,
                                            ),
                                          ),
                                        )
                                    : null,
                                child: _StatColumn(label: 'Following', value: _count('following')),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Follow button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isFollowLoading ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? AppColors.surface : AppColors.accent,
                                foregroundColor: _isFollowing ? AppColors.textPrimary : Colors.white,
                                side: _isFollowing
                                    ? BorderSide(color: AppColors.border)
                                    : BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isFollowLoading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _isFollowing ? AppColors.accent : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Videos', style: AppTextStyles.headingMedium),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Video grid
                  if (_videos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No videos yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final video = _videos[index];
                            final vAccent = video['accent'] is Color
                                ? video['accent'] as Color
                                : AppColors.accent;
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _VideoPlayerScreen(video: video),
                                ),
                              ),
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
                                        color: vAccent.withValues(alpha: 0.5),
                                        size: 40,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
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
                                        child: Text(
                                          video['title']?.toString() ?? '',
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _videos.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
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
          video['title']?.toString() ?? '',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
      ),
      body: video['filePath'] != null
          ? VideoPlayerWidget(filePath: video['filePath'] as String)
          : video['networkUrl'] != null
              ? VideoPlayerWidget(networkUrl: video['networkUrl'] as String)
              : Center(
                  child: Text(
                    'Video unavailable',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
    );
  }
}
