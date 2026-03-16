import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'alerts_screen.dart';
import 'messages_screen.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/share_sheet.dart';
import '../models/video_store.dart';
import '../widgets/video_player_widget.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    setState(() {
      _videos = VideoStore.videos.map((v) => {
        ...v,
        'color': Color(v['color'] as int),
        'accent': Color(v['accent'] as int),
      }).toList();
    });
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
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return _VideoCard(video: _videos[index]);
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo wordmark
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Reel',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Scholar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 19,
                            fontWeight: FontWeight.w300,
                            color: AppColors.accentLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top right icons
                  Row(
                    children: [
                      // Messages
                      _TopBarButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MessagesScreen()),
                        ),
                        icon: Icons.chat_bubble_outline_rounded,
                        hasBadge: true,
                      ),
                      const SizedBox(width: 8),
                      // Search
                      _TopBarButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        ),
                        icon: Icons.search_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomNav(
              currentIndex: _currentIndex == 0 ? 0 : 0,
              onRefresh: _loadVideos,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
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
  }

  Widget _buildDemoPlaceholder(Color accent, Map<String, dynamic> video) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
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
                video['subject'],
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
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
          colors: [
            bgColor,
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative background circle
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Video player — real if file exists, placeholder if not
          Positioned.fill(
            child: (video['fileBytes'] != null)
                ? VideoPlayerWidget(fileBytes: video['fileBytes'] as List<int>)
                : (video['filePath'] != null)
                    ? VideoPlayerWidget(filePath: video['filePath'] as String)
                    : (video['networkUrl'] != null)
                        ? VideoPlayerWidget(networkUrl: video['networkUrl'] as String)
                        : _buildDemoPlaceholder(accent, video),
          ),

          // Bottom content overlay
          Positioned(
            bottom: 80,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: accent.withValues(alpha: 0.3),
                      child: Text(
                        video['name'].toString().substring(0, 1),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          video['username'],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Video title
                Text(
                  video['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                // Like
                _ActionButton(
                  onTap: _handleLike,
                  child: AnimatedBuilder(
                    animation: _heartController,
                    builder: (_, __) => Transform.scale(
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
                  label: video['likes'],
                ),
                const SizedBox(height: 20),

                // Comment
                _ActionButton(
                  onTap: () => showComments(context, video['title']),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  label: video['comments'],
                ),
                const SizedBox(height: 20),

                // Share
                _ActionButton(
                  onTap: () => showShareSheet(context, video['title'], video['username']),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  label: video['shares'],
                ),
                const SizedBox(height: 20),

                // Quiz button
                GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: AppColors.accentLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quiz',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String label;

  const _ActionButton({
    required this.onTap,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool hasBadge;

  const _TopBarButton({
    required this.onTap,
    required this.icon,
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            if (hasBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLight,
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

class _BottomNav extends StatefulWidget {
  final int currentIndex;
  final VoidCallback onRefresh;
  const _BottomNav({required this.currentIndex, required this.onRefresh});

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  int _selected = 0;

  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.search_rounded, 'label': 'Discover'},
    {'icon': Icons.add_circle_rounded, 'label': 'Upload'},
    {'icon': Icons.notifications_outlined, 'label': 'Alerts'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.97),
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final bool isSelected = _selected == index;
          final bool isUpload = index == 2;

          if (isUpload) {
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
                widget.onRefresh();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              setState(() => _selected = index);
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.accentLight
                            : AppColors.textTertiary,
                        size: 22,
                      ),
                      if (index == 3)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accentLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      color: isSelected
                          ? AppColors.accentLight
                          : AppColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}