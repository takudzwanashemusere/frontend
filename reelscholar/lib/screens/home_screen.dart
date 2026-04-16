import 'package:flutter/material.dart';
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
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _videos = [];
  int _selectedFeedTab = 0; // 0=For You, 1=Following, 2=My School
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
      // Prepend any locally-uploaded videos that haven't synced yet
      final local = VideoStore.videos.map((v) => {
        ...v,
        'color': v['color'] is Color ? v['color'] : Color(v['color'] as int),
        'accent': v['accent'] is Color ? v['accent'] : Color(v['accent'] as int),
      }).toList();
      if (mounted) setState(() { _videos = [...local, ...apiVideos]; _isLoading = false; });
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
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const _AppDrawer(),
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
              onPageChanged: (_) {},
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return _VideoCard(video: _videos[index]);
              },
            ),

          // Top bar + feed tabs
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: hamburger + logo
                      Row(
                        children: [
                          _TopBarButton(
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: Icons.menu_rounded,
                          ),
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
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
                        ],
                      ),
                      // Right icons
                      Row(
                        children: [
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
                // Feed tab switcher
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
            bottom: 28,
            left: 0,
            right: 0,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
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
        if (mounted) setState(() => _isLiked = !_isLiked); // revert on error
      });
    }
  }

  void _handleFollow() {
    final userId = widget.video['userId'];
    if (userId == null) return;
    setState(() => _isFollowing = !_isFollowing);
    VideoService.toggleFollow(userId).catchError((_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing); // revert on error
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
            child: (video['filePath'] != null)
                ? VideoPlayerWidget(filePath: video['filePath'] as String)
                : (video['networkUrl'] != null)
                    ? VideoPlayerWidget(networkUrl: video['networkUrl'] as String)
                    : (video['fileBytes'] != null)
                        ? VideoPlayerWidget(fileBytes: video['fileBytes'] as List<int>)
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
                // Username row
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openUserProfile,
                      child: CircleAvatar(
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
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: GestureDetector(
                        onTap: _openUserProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['name'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              video['username'],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _handleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
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

                // Comment
                _ActionButton(
                  onTap: () => showComments(context, video['title'], videoId: video['id']),
                  label: video['comments'],
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // Share
                _ActionButton(
                  onTap: () => showShareSheet(context, video['title'], video['username']),
                  label: video['shares'],
                  child: const Icon(
                    Icons.reply_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // Quiz button
                GestureDetector(
                  onTap: () => showQuiz(
                    context,
                    video['subject'] as String,
                    video['title'] as String,
                  ),
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
                        child: Icon(
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
                  decoration: BoxDecoration(
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

// ─── Feed Tab Switcher ────────────────────────────────────────────────────────

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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  static const _items = [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'route': 'dashboard'},
    {'icon': Icons.home_rounded, 'label': 'Video Feed', 'route': 'home'},
    {'icon': Icons.search_rounded, 'label': 'Discover', 'route': 'discover'},
    {'icon': Icons.emoji_events_outlined, 'label': 'Hackathon', 'route': 'hackathon'},
    {'icon': Icons.notifications_outlined, 'label': 'Alerts', 'route': 'alerts'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profile', 'route': 'profile'},
    {'icon': Icons.auto_awesome_outlined, 'label': 'Chat with AI', 'route': 'ai'},
    {'icon': Icons.quiz_outlined, 'label': 'Take a Quiz', 'route': 'quiz'},
    {'icon': Icons.contrast_rounded, 'label': 'Appearance', 'route': 'theme'},
  ];

  void _navigate(BuildContext context, String route) {
    if (route == 'ai') {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Chat with AI — coming soon!',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (route == 'quiz') {
      Navigator.pop(context);
      _showSubjectPicker(context);
      return;
    }
    if (route == 'theme') {
      Navigator.pop(context);
      _showThemePicker(context);
      return;
    }
    Navigator.pop(context);
    switch (route) {
      case 'home':
        break;
      case 'dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;
      case 'discover':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 'hackathon':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HackathonScreen()),
        );
        break;
      case 'alerts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlertsScreen()),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThemePickerSheet(),
    );
  }

  // Faculty → Semester → Modules
  static const Map<String, Map<int, List<String>>> _semesterModules = {
    'School of Engineering Science and Technology': {
      1: ['Software Engineering Fundamentals', 'Introduction to Programming', 'Mathematics 1', 'ICT Fundamentals', 'Communication Skills'],
      2: ['Data Structures & Algorithms', 'Database Systems', 'Web Development', 'Mathematics 2', 'Technical Writing'],
      3: ['Software Design Patterns', 'Networking Fundamentals', 'Operating Systems', 'Statistics & Probability', 'Technical English'],
      4: ['Mobile App Development', 'Cyber Security', 'Cloud Computing', 'Artificial Intelligence', 'Software Project Management'],
      5: ['System Analysis & Design', 'Software Testing', 'Advanced Databases', 'Machine Learning', 'Research Methods'],
      6: ['Final Year Project', 'Software Architecture', 'DevOps & CI/CD', 'Entrepreneurship', 'ICT Law & Ethics'],
      7: ['Advanced Software Engineering', 'Distributed Systems', 'Blockchain Technology', 'Data Science', 'Technical Management'],
      8: ['Dissertation', 'Enterprise Architecture', 'Advanced Networking', 'Innovation & Technology', 'Professional Ethics'],
    },
    'School of Agriculture Sciences and Technology': {
      1: ['Introduction to Agriculture', 'Crop Science I', 'Soil Science I', 'Mathematics 1', 'Communication Skills'],
      2: ['Crop Science II', 'Soil Science II', 'Plant Physiology', 'Agricultural Chemistry', 'Technical Writing'],
      3: ['Animal Science I', 'Irrigation Systems', 'Agricultural Economics', 'Research Methods', 'Agronomy'],
      4: ['Animal Science II', 'Crop Protection', 'Farm Management', 'Agricultural Extension', 'Environmental Science'],
      5: ['Advanced Crop Production', 'Livestock Management', 'Environmental Impact Assessment', 'Agribusiness', 'Remote Sensing'],
      6: ['Final Year Project', 'Agricultural Policy', 'Food Science', 'Entrepreneurship', 'Post-Harvest Technology'],
      7: ['Advanced Animal Husbandry', 'Precision Agriculture', 'Agricultural Biotechnology', 'Watershed Management', 'Rural Development'],
      8: ['Dissertation', 'Agricultural Finance', 'International Agri-Trade', 'Climate Smart Agriculture', 'Professional Practice'],
    },
    'School of Entrepreneurship and Business Sciences': {
      1: ['Introduction to Business', 'Mathematics for Business', 'Communication Skills', 'Principles of Management', 'Economics I'],
      2: ['Accounting I', 'Marketing Fundamentals', 'Business Law', 'Statistics for Business', 'Economics II'],
      3: ['Financial Management', 'Entrepreneurship I', 'Human Resource Management', 'Business Research Methods', 'Microeconomics'],
      4: ['Strategic Management', 'Entrepreneurship II', 'Operations Management', 'Business Ethics', 'Macroeconomics'],
      5: ['Financial Modelling', 'Investment Analysis', 'Supply Chain Management', 'Digital Marketing', 'International Business'],
      6: ['Final Year Project', 'Corporate Governance', 'Venture Capital', 'Entrepreneurship & Innovation', 'Business Strategy'],
      7: ['Advanced Accounting', 'Mergers & Acquisitions', 'E-Commerce', 'Business Intelligence', 'Taxation'],
      8: ['Dissertation', 'Advanced Financial Management', 'Global Business Strategy', 'Social Entrepreneurship', 'Professional Ethics'],
    },
    'School of Health Sciences and Technology': {
      1: ['Anatomy & Physiology I', 'Introduction to Health Sciences', 'Mathematics', 'Communication Skills', 'Medical Terminology'],
      2: ['Anatomy & Physiology II', 'Biochemistry', 'Microbiology', 'Pharmacology I', 'Nutrition Science'],
      3: ['Pathology', 'Pharmacology II', 'Clinical Skills I', 'Public Health', 'Research Methods'],
      4: ['Clinical Skills II', 'Community Health', 'Epidemiology', 'Medical Ethics', 'Health Policy'],
      5: ['Advanced Clinical Practice', 'Mental Health', 'Maternal & Child Health', 'Disease Prevention', 'Health Informatics'],
      6: ['Final Year Project', 'Healthcare Management', 'Geriatric Care', 'Emergency Medicine', 'Global Health'],
      7: ['Advanced Pharmacology', 'Surgical Nursing', 'Critical Care', 'Health Systems Management', 'Medical Research'],
      8: ['Dissertation', 'Health Economics', 'Advanced Public Health', 'Healthcare Leadership', 'Professional Ethics'],
    },
    'School of Wildlife and Environmental Science': {
      1: ['Introduction to Wildlife', 'Ecology I', 'Environmental Science I', 'Mathematics', 'Communication Skills'],
      2: ['Ecology II', 'Zoology', 'Botany', 'Conservation Biology', 'Environmental Science II'],
      3: ['Wildlife Management I', 'Remote Sensing & GIS', 'Animal Behaviour', 'Research Methods', 'Environmental Policy'],
      4: ['Wildlife Management II', 'Protected Area Management', 'Tourism & Conservation', 'Environmental Impact Assessment', 'Aquatic Science'],
      5: ['Advanced Ecology', 'Human-Wildlife Conflict', 'Climate Change', 'Biodiversity Conservation', 'Conservation Finance'],
      6: ['Final Year Project', 'Environmental Law', 'Wildlife Photography', 'Entrepreneurship', 'Global Conservation Issues'],
      7: ['Advanced Wildlife Management', 'Landscape Ecology', 'Marine Biology', 'Conservation Genetics', 'Environmental Consultancy'],
      8: ['Dissertation', 'Wildlife Policy', 'Advanced GIS', 'Environmental Economics', 'Professional Ethics'],
    },
    'School of Hospitality and Tourism': {
      1: ['Introduction to Hospitality', 'Tourism Fundamentals', 'Communication Skills', 'Mathematics', 'Food & Beverage I'],
      2: ['Hotel Operations', 'Tourism Marketing', 'Food & Beverage II', 'Front Office Management', 'Business Communication'],
      3: ['Tourism Planning', 'Event Management', 'Revenue Management', 'Customer Service', 'Research Methods'],
      4: ['Hotel Financial Management', 'Tourism Policy', 'Sustainable Tourism', 'Human Resources in Hospitality', 'Digital Tourism'],
      5: ['Advanced Hotel Management', 'Tour Guiding', 'International Tourism', 'Strategic Management', 'Ecotourism'],
      6: ['Final Year Project', 'Tourism Entrepreneurship', 'Convention & Meetings Management', 'Crisis Management', 'Heritage Tourism'],
      7: ['Advanced Food Science', 'Destination Management', 'Tourism Economics', 'Hospitality Technology', 'Luxury Brand Management'],
      8: ['Dissertation', 'Global Tourism Trends', 'Hospitality Leadership', 'Cultural Tourism', 'Professional Ethics'],
    },
  };

  void _showSubjectPicker(BuildContext context) async {
    final faculty = await AuthService.getDepartment();
    final semester = await AuthService.getSemester();

    if (!context.mounted) return;

    // Get modules for this faculty + semester
    final facultyModules = _semesterModules[faculty ?? ''] ?? {};
    final modules = facultyModules[semester] ?? [];

    // Fall back to General if no modules found
    final subjects = modules.isNotEmpty ? modules : ['General'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
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
                          Text(
                            'Semester $semester Modules',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (faculty != null && faculty.isNotEmpty)
                            Text(
                              faculty,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Sem $semester',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select a module and test your knowledge',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subjects.length,
                  itemBuilder: (c, i) {
                    final subject = subjects[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(c);
                          showQuiz(context, subject, subject);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: AppColors.accentLight,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white38,
                                size: 14,
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Reel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: 'Scholar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: AppColors.accentLight,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: AppColors.border,
                thickness: 1,
              ),
            ),

            const SizedBox(height: 8),

            // Nav items
            ...(_items.map((item) {
              final bool isAI = item['route'] == 'ai';
              return _DrawerItem(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                isAccent: isAI,
                hasBadge: item['route'] == 'alerts',
                onTap: () => _navigate(context, item['route'] as String),
              );
            })),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAccent;
  final bool hasBadge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isAccent ? AppColors.accentLight : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.accent.withValues(alpha: 0.1),
      highlightColor: AppColors.accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isAccent
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (hasBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isAccent ? AppColors.accentLight : Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              if (isAccent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentLight,
                      letterSpacing: 1,
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

// ─── Theme Picker Sheet ───────────────────────────────────────────────────────

class _ThemePickerSheet extends StatefulWidget {
  @override
  State<_ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<_ThemePickerSheet> {
  AppThemeMode _selected = ThemeService.current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            'Appearance',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose between dark and light mode',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _ThemeOption(
                mode: AppThemeMode.dark,
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: _selected == AppThemeMode.dark,
                onTap: () {
                  setState(() => _selected = AppThemeMode.dark);
                  ThemeService.setMode(AppThemeMode.dark);
                },
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                mode: AppThemeMode.light,
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: _selected == AppThemeMode.light,
                onTap: () {
                  setState(() => _selected = AppThemeMode.light);
                  ThemeService.setMode(AppThemeMode.light);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGlow : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}