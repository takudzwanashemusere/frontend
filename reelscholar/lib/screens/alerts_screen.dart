import 'package:flutter/material.dart';
import '../main.dart';
import '../services/video_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = false;

  // Map a raw API notification to the format expected by the UI
  Map<String, dynamic> _normalizeNotification(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? 'system';
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'like':
        icon = Icons.favorite_rounded;
        iconColor = AppColors.error;
        break;
      case 'comment':
        icon = Icons.chat_bubble_rounded;
        iconColor = AppColors.accent;
        break;
      case 'follow':
        icon = Icons.person_add_rounded;
        iconColor = AppColors.accentLight;
        break;
      default:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
    }
    final notifier = (n['notifier'] is Map)
        ? n['notifier'] as Map<String, dynamic>
        : (n['from_user'] is Map)
            ? n['from_user'] as Map<String, dynamic>
            : <String, dynamic>{};
    return {
      'id': n['id'],
      'type': type,
      'name': notifier['name'] ?? n['name'] ?? 'ReelScholar',
      'action': n['message'] ?? n['action'] ?? '',
      'target': n['target'] ?? n['video_title'] ?? '',
      'time': n['created_at']?.toString() ?? '',
      'isRead': n['read_at'] != null || n['is_read'] == true,
      'icon': icon,
      'iconColor': iconColor,
    };
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final raw = await VideoService.getNotifications();
      if (mounted) {
        setState(() {
          _allNotifications = raw.map(_normalizeNotification).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _unreadCount =>
      _allNotifications.where((n) => n['isRead'] == false).length;

  void _markAllRead() {
    setState(() {
      for (var n in _allNotifications) {
        n['isRead'] = true;
      }
    });
    VideoService.markAllNotificationsRead().catchError((_) {});
  }

  void _markRead(int index) {
    final notif = _allNotifications[index];
    setState(() => notif['isRead'] = true);
    if (notif['id'] != null) {
      VideoService.markNotificationRead(notif['id']).catchError((_) {});
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Alerts',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
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
            Tab(text: 'All'),
            Tab(text: 'Activity'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_filterByType('all')),
                _buildNotificationList(
                  _allNotifications
                      .where((n) =>
                          n['type'] == 'like' ||
                          n['type'] == 'comment' ||
                          n['type'] == 'follow')
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
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 14),
            Text('No notifications', style: AppTextStyles.headingMedium),
            SizedBox(height: 6),
            Text("You're all caught up!", style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    final unread = items.where((n) => n['isRead'] == false).toList();
    final read = items.where((n) => n['isRead'] == true).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (unread.isNotEmpty) ...[
          _buildSectionHeader('New'),
          ...unread.map((e) =>
              _buildNotificationTile(e, _allNotifications.indexOf(e))),
        ],
        if (read.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...read.map((e) =>
              _buildNotificationTile(e, _allNotifications.indexOf(e))),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif, int index) {
    final bool isRead = notif['isRead'] as bool;
    final IconData iconData = notif['icon'] as IconData;
    final Color iconColor = notif['iconColor'] as Color;

    // Derive an initial color from the name
    final initial = notif['name'].toString().substring(0, 1);

    return GestureDetector(
      onTap: () => _markRead(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + icon badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

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
                            fontFamily: 'Poppins',
                            color: isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: ' ${notif['action']}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: isRead
                                ? AppColors.textTertiary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((notif['target'] as String).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notif['target'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    notif['time'],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead)
              Container(
                width: 7,
                height: 7,
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
