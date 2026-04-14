import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/video_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _query = '';
  bool _isLoadingTrending = true;
  bool _isSearching = false;

  List<Map<String, dynamic>> _trendingVideos = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];

  static const _prefsKey = 'recent_searches';

  final List<String> _tabs = [
    'All',
    'Engineering',
    'Business',
    'Agriculture',
    'Health',
    'Natural Sci',
  ];

  // Schools are fixed (CUT faculties) — names and icons are static
  static const _schools = [
    {
      'name': 'Engineering Science\n& Technology',
      'icon': Icons.engineering_outlined,
      'color': AppColors.accent,
      'school': 'Engineering',
    },
    {
      'name': 'Entrepreneurship\n& Business Sciences',
      'icon': Icons.business_center_outlined,
      'color': Color(0xFFFF6B35),
      'school': 'Business',
    },
    {
      'name': 'Agriculture Sciences\n& Technology',
      'icon': Icons.agriculture_outlined,
      'color': Color(0xFF2ECC71),
      'school': 'Agriculture',
    },
    {
      'name': 'Natural Sciences\n& Mathematics',
      'icon': Icons.science_outlined,
      'color': Color(0xFF00BCD4),
      'school': 'Natural Sciences',
    },
    {
      'name': 'Health Sciences\n& Technology',
      'icon': Icons.local_hospital_outlined,
      'color': Color(0xFFE040FB),
      'school': 'Health',
    },
    {
      'name': 'Wildlife &\nEnvironmental Science',
      'icon': Icons.park_outlined,
      'color': Color(0xFF4CAF50),
      'school': 'Wildlife',
    },
    {
      'name': 'Hospitality\n& Tourism',
      'icon': Icons.hotel_outlined,
      'color': Color(0xFFFFAB40),
      'school': 'Hospitality',
    },
    {
      'name': 'Art\n& Design',
      'icon': Icons.palette_outlined,
      'color': Color(0xFFFF4081),
      'school': 'Art',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadTrending();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    try {
      final videos = await VideoService.getTrending();
      if (mounted) setState(() { _trendingVideos = videos; _isLoadingTrending = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    if (mounted) setState(() => _recentSearches = saved);
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [
      query.trim(),
      ..._recentSearches.where((s) => s != query.trim()),
    ].take(8).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;
    _saveSearch(query);
    setState(() => _isSearching = true);
    try {
      final results = await VideoService.searchVideos(query.trim());
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Find educational content across CUT schools',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _query.isNotEmpty
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() { _query = val; _searchResults = []; });
                      },
                      onSubmitted: _runSearch,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search modules, schools, topics...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textTertiary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _query = ''; _searchResults = []; });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),

            Expanded(
              child: _query.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDiscoverContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: AppTextStyles.headingMedium),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s;
                    setState(() => _query = s);
                    _runSearch(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Browse by School
          Text('Browse by School', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: _schools.length,
            itemBuilder: (context, index) {
              final school = _schools[index];
              final Color color = school['color'] as Color;
              return GestureDetector(
                onTap: () {
                  final schoolName = school['school'] as String;
                  _searchController.text = schoolName;
                  setState(() => _query = schoolName);
                  _runSearch(schoolName);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          school['icon'] as IconData,
                          color: color,
                          size: 20,
                        ),
                      ),
                      Text(
                        school['name'] as String,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Trending Now
          Row(
            children: [
              Text('Trending Now', style: AppTextStyles.headingMedium),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentLight,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingTrending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_trendingVideos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No trending content right now',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ..._trendingVideos.map((video) => _TrendingCard(video: video)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press Enter / Search to look it up',
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _TrendingCard(video: _searchResults[index]),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> video;
  const _TrendingCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final Color color = video['color'] is Color
        ? video['color'] as Color
        : AppColors.accent;
    final String title = video['title']?.toString() ?? '';
    final String subject = video['subject']?.toString() ?? '';
    final String author = video['username']?.toString() ??
        video['name']?.toString() ??
        video['author']?.toString() ??
        '';
    final String stat = video['likes']?.toString() ??
        video['views']?.toString() ??
        '0';
    final bool isViews = video['views'] != null && video['likes'] == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (subject.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: color,
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (subject.isNotEmpty) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        author,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontFamily: 'Poppins',
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                isViews ? Icons.visibility_outlined : Icons.favorite_border_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                stat,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
