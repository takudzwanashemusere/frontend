import 'package:flutter/material.dart';
import '../main.dart';

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

  final List<String> _tabs = [
    'All',
    'Engineering',
    'Business',
    'Agriculture',
    'Health',
    'Natural Sci',
  ];

  final List<Map<String, dynamic>> _trending = [
    {
      'subject': 'Software Engineering',
      'school': 'Engineering Science and Technology',
      'title': 'Introduction to Flutter — Building mobile apps at CUT',
      'author': '@tatenda_m',
      'views': '12.4K',
      'color': AppColors.accent,
    },
    {
      'subject': 'Business Management',
      'school': 'Entrepreneurship and Business Sciences',
      'title': 'How to write a Business Plan that actually works',
      'author': '@simba_biz',
      'views': '9.1K',
      'color': const Color(0xFFFF6B35),
    },
    {
      'subject': 'Crop Science',
      'school': 'Agriculture Sciences and Technology',
      'title': 'Soil Fertility Management for Zimbabwean Farmers',
      'author': '@rudo_agri',
      'views': '7.8K',
      'color': const Color(0xFF2ECC71),
    },
    {
      'subject': 'Wildlife Management',
      'school': 'Wildlife and Environmental Science',
      'title': "Conservation strategies for Zimbabwe's wildlife reserves",
      'author': '@taku_wildlife',
      'views': '6.3K',
      'color': const Color(0xFF00BCD4),
    },
    {
      'subject': 'Public Health',
      'school': 'Health Sciences and Technology',
      'title': 'Understanding the Human Immune System',
      'author': '@panashe_health',
      'views': '4.9K',
      'color': const Color(0xFFE040FB),
    },
    {
      'subject': 'Hotel Management',
      'school': 'Hospitality and Tourism',
      'title': 'Front Office Operations in Modern Hotels',
      'author': '@chiedza_hosp',
      'views': '3.7K',
      'color': AppColors.accent,
    },
  ];

  final List<String> _recentSearches = [
    'software engineering',
    'crop science',
    'business plan',
    'wildlife conservation',
  ];

  final List<Map<String, dynamic>> _schools = [
    {
      'name': 'Engineering Science\n& Technology',
      'icon': Icons.engineering_outlined,
      'color': AppColors.accent,
      'count': '312 videos',
    },
    {
      'name': 'Entrepreneurship\n& Business Sciences',
      'icon': Icons.business_center_outlined,
      'color': const Color(0xFFFF6B35),
      'count': '248 videos',
    },
    {
      'name': 'Agriculture Sciences\n& Technology',
      'icon': Icons.agriculture_outlined,
      'color': const Color(0xFF2ECC71),
      'count': '183 videos',
    },
    {
      'name': 'Natural Sciences\n& Mathematics',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF00BCD4),
      'count': '201 videos',
    },
    {
      'name': 'Health Sciences\n& Technology',
      'icon': Icons.local_hospital_outlined,
      'color': const Color(0xFFE040FB),
      'count': '156 videos',
    },
    {
      'name': 'Wildlife &\nEnvironmental Science',
      'icon': Icons.park_outlined,
      'color': const Color(0xFF4CAF50),
      'count': '94 videos',
    },
    {
      'name': 'Hospitality\n& Tourism',
      'icon': Icons.hotel_outlined,
      'color': AppColors.accentLight,
      'count': '127 videos',
    },
    {
      'name': 'Art\n& Design',
      'icon': Icons.palette_outlined,
      'color': const Color(0xFFFF4081),
      'count': '89 videos',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
                  const Text('Discover', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  const Text(
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
                      onChanged: (val) => setState(() => _query = val),
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
                                  setState(() => _query = '');
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
                const Text('Recent', style: AppTextStyles.headingMedium),
                GestureDetector(
                  onTap: () {},
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
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
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
          const Text('Browse by School', style: AppTextStyles.headingMedium),
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
                onTap: () {},
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school['name'],
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            school['count'],
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'Poppins',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Trending
          Row(
            children: [
              Text('Trending Now', style: AppTextStyles.headingMedium),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ..._trending.map((video) => _TrendingCard(video: video)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _trending
        .where((v) =>
            v['title']
                .toString()
                .toLowerCase()
                .contains(_query.toLowerCase()) ||
            v['subject']
                .toString()
                .toLowerCase()
                .contains(_query.toLowerCase()) ||
            v['school']
                .toString()
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) => _TrendingCard(video: results[index]),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> video;
  const _TrendingCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final Color color = video['color'] as Color;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
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
            child: Icon(
              Icons.play_arrow_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'],
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
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video['subject'],
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        video['author'],
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
                Icons.visibility_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                video['views'],
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
