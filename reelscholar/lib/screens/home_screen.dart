import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'upload_screen.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/share_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Dummy video data — replace with real API data later
  final List<Map<String, dynamic>> _videos = [
    {
      'username': '@tatenda_math',
      'name': 'Tatenda Moyo',
      'subject': 'Mathematics',
      'title': 'Solving Quadratic Equations in 60 seconds 🔥',
      'likes': '2.4K',
      'comments': '183',
      'shares': '92',
      'color': const Color(0xFF1A1040),
      'accent': const Color(0xFF6C63FF),
    },
    {
      'username': '@rudo_biology',
      'name': 'Rudo Chikwanda',
      'subject': 'Biology',
      'title': 'How DNA Replication works — simple explanation 🧬',
      'likes': '1.8K',
      'comments': '97',
      'shares': '44',
      'color': const Color(0xFF0D2818),
      'accent': const Color(0xFF2ECC71),
    },
    {
      'username': '@simba_ict',
      'name': 'Simba Kowo',
      'subject': 'ICT',
      'title': 'Flutter vs React Native — which one for CUT students? 📱',
      'likes': '3.1K',
      'comments': '256',
      'shares': '130',
      'color': const Color(0xFF1A0A00),
      'accent': const Color(0xFFFF6B35),
    },
    {
      'username': '@panashe_chem',
      'name': 'Panashe Dzingira',
      'subject': 'Chemistry',
      'title': 'Understanding Ionic vs Covalent Bonds ⚗️',
      'likes': '987',
      'comments': '64',
      'shares': '28',
      'color': const Color(0xFF1A0020),
      'accent': const Color(0xFFE040FB),
    },
    {
      'username': '@taku_physics',
      'name': 'Takudzwa Musere',
      'subject': 'Physics',
      'title': "Newton's 3 Laws explained with real examples 🚀",
      'likes': '4.2K',
      'comments': '312',
      'shares': '201',
      'color': const Color(0xFF001A2A),
      'accent': const Color(0xFF00BCD4),
    },
  ];

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Reel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'Scholar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
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
            child: _BottomNav(currentIndex: _currentIndex == 0 ? 0 : 0),
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

          // Video placeholder (replace with actual video player later)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: accent,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
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
                        border: Border.all(color: accent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Follow',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.quiz_outlined,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quiz',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatefulWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
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
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white38,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white38,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}