import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'type': 'like',
      'name': 'Tatenda Moyo',
      'action': 'liked your video',
      'target': 'Solving Quadratic Equations in 60 seconds 🔥',
      'time': '2m ago',
      'isRead': false,
      'color': const Color(0xFF6C63FF),
      'icon': Icons.favorite_rounded,
      'iconColor': Colors.redAccent,
    },
    {
      'type': 'comment',
      'name': 'Rudo Chikwanda',
      'action': 'commented on your video',
      'target': '"This helped me so much for my test!"',
      'time': '8m ago',
      'isRead': false,
      'color': const Color(0xFF2ECC71),
      'icon': Icons.chat_bubble_rounded,
      'iconColor': const Color(0xFF2ECC71),
    },
    {
      'type': 'follow',
      'name': 'Simba Kowo',
      'action': 'started following you',
      'target': '',
      'time': '15m ago',
      'isRead': false,
      'color': const Color(0xFFFF6B35),
      'icon': Icons.person_add_rounded,
      'iconColor': const Color(0xFF6C63FF),
    },
    {
      'type': 'like',
      'name': 'Panashe Dzingira',
      'action': 'liked your video',
      'target': 'Newton\'s 3 Laws explained 🚀',
      'time': '32m ago',
      'isRead': true,
      'color': const Color(0xFFE040FB),
      'icon': Icons.favorite_rounded,
      'iconColor': Colors.redAccent,
    },
    {
      'type': 'comment',
      'name': 'Farai Mutasa',
      'action': 'replied to your comment',
      'target': '"Agreed! This app is amazing for studying"',
      'time': '1h ago',
      'isRead': true,
      'color': const Color(0xFF00BCD4),
      'icon': Icons.chat_bubble_rounded,
      'iconColor': const Color(0xFF2ECC71),
    },
    {
      'type': 'system',
      'name': 'ReelScholar',
      'action': 'Your video was approved and is now live!',
      'target': 'Databases Introduction for ICT Students',
      'time': '2h ago',
      'isRead': true,
      'color': const Color(0xFF6C63FF),
      'icon': Icons.check_circle_rounded,
      'iconColor': const Color(0xFF2ECC71),
    },
    {
      'type': 'follow',
      'name': 'Chiedza Mupfumi',
      'action': 'started following you',
      'target': '',
      'time': '3h ago',
      'isRead': true,
      'color': const Color(0xFFFFD700),
      'icon': Icons.person_add_rounded,
      'iconColor': const Color(0xFF6C63FF),
    },
    {
      'type': 'system',
      'name': 'ReelScholar',
      'action': 'Welcome to ReelScholar! Start by uploading your first video.',
      'target': 'Tap the + button to get started',
      'time': '1d ago',
      'isRead': true,
      'color': const Color(0xFF6C63FF),
      'icon': Icons.school_rounded,
      'iconColor': const Color(0xFFFFD700),
    },
  ];

  int get _unreadCount =>
      _allNotifications.where((n) => n['isRead'] == false).length;

  void _markAllRead() {
    setState(() {
      for (var n in _allNotifications) {
        n['isRead'] = true;
      }
    });
  }

  void _markRead(int index) {
    setState(() => _allNotifications[index]['isRead'] = true);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterByType(String type) {
    if (type == 'all') return _allNotifications;
    return _allNotifications.where((n) => n['type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            const Text(
              'Alerts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 2,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Activity'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_filterByType('all')),
          _buildNotificationList(
            _allNotifications
                .where((n) => n['type'] == 'like' || n['type'] == 'comment' || n['type'] == 'follow')
                .toList(),
          ),
          _buildNotificationList(_filterByType('system')),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            const Text('No notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('You\'re all caught up!',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13)),
          ],
        ),
      );
    }

    // Group by time
    final unread = items.where((n) => n['isRead'] == false).toList();
    final read = items.where((n) => n['isRead'] == true).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (unread.isNotEmpty) ...[
          _buildSectionHeader('New'),
          ...unread.asMap().entries.map((e) =>
              _buildNotificationTile(e.value, _allNotifications.indexOf(e.value))),
        ],
        if (read.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...read.asMap().entries.map((e) =>
              _buildNotificationTile(e.value, _allNotifications.indexOf(e.value))),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif, int index) {
    final bool isRead = notif['isRead'] as bool;
    final Color avatarColor = notif['color'] as Color;
    final IconData iconData = notif['icon'] as IconData;
    final Color iconColor = notif['iconColor'] as Color;

    return GestureDetector(
      onTap: () => _markRead(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? const Color(0xFF12121A)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFF6C63FF).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with icon badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor.withValues(alpha: 0.2),
                  child: Text(
                    notif['name'].toString().substring(0, 1),
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0A0A0F), width: 1.5),
                    ),
                    child: Icon(iconData, color: iconColor, size: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notif['name'],
                          style: TextStyle(
                            color: isRead ? Colors.white70 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: ' ${notif['action']}',
                          style: TextStyle(
                            color: isRead
                                ? Colors.white38
                                : Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((notif['target'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif['target'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    notif['time'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}