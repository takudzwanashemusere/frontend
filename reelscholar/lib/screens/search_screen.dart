import 'package:flutter/material.dart';

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
      'color': const Color(0xFF6C63FF),
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
      'color': const Color(0xFFFFD700),
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
      'color': const Color(0xFF6C63FF),
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
      'color': const Color(0xFFFFD700),
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
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discover',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Find educational content across CUT schools',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.45))),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _query.isNotEmpty
                              ? const Color(0xFF6C63FF)
                              : Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _query = val),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'Search modules, schools, topics...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF6C63FF), size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white38, size: 20),
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
              indicatorColor: const Color(0xFF6C63FF),
              indicatorWeight: 2,
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),

            const SizedBox(height: 8),

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Clear all',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6C63FF))),
                ),
              ],
            ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        Text(s,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Browse by School
          const Text('Browse by School',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _schools.length,
            itemBuilder: (context, index) {
              final school = _schools[index];
              final Color color = school['color'] as Color;
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(school['icon'] as IconData,
                          color: color, size: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(school['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                              maxLines: 2),
                          const SizedBox(height: 2),
                          Text(school['count'],
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.4),
                                  fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const Text('🔥 Trending Now',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
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
            Icon(Icons.search_off_rounded,
                size: 60, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No results for "$_query"',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _TrendingCard(video: results[index]),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(video['subject'],
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(video['author'],
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 14, color: Colors.white38),
              const SizedBox(height: 2),
              Text(video['views'],
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}