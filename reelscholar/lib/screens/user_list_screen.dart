import 'package:flutter/material.dart';
import '../main.dart';
import '../services/video_service.dart';
import 'user_profile_screen.dart';

enum UserListType { followers, following }

class UserListScreen extends StatefulWidget {
  final dynamic userId;
  final UserListType type;
  final String ownerName;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.ownerName,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  // Follow state keyed by user id
  final Map<dynamic, bool> _followState = {};

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _page = 1; _hasMore = true; });
    try {
      final list = await _fetch(1);
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
          _hasMore = list.length >= 20;
          for (final u in list) {
            _followState[u['id']] = u['is_following'] == true;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final list = await _fetch(next);
      if (mounted) {
        setState(() {
          _page = next;
          _users.addAll(list);
          _hasMore = list.length >= 20;
          _isLoadingMore = false;
          for (final u in list) {
            _followState[u['id']] = u['is_following'] == true;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(int page) {
    if (widget.type == UserListType.followers) {
      return VideoService.getFollowers(widget.userId, page: page);
    }
    return VideoService.getFollowing(widget.userId, page: page);
  }

  Future<void> _toggleFollow(dynamic userId) async {
    final prev = _followState[userId] ?? false;
    setState(() => _followState[userId] = !prev);
    try {
      await VideoService.toggleFollow(userId);
    } catch (_) {
      if (mounted) setState(() => _followState[userId] = prev);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == UserListType.followers
        ? 'Followers'
        : 'Following';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.ownerName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _users.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _UserTile(
                        user: _users[index],
                        isFollowing: _followState[_users[index]['id']] ?? false,
                        initials: _initials(
                          _users[index]['name']?.toString() ??
                              _users[index]['username']?.toString() ??
                              '?',
                        ),
                        onFollowTap: () => _toggleFollow(_users[index]['id']),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              userId: _users[index]['id'],
                              displayName: _users[index]['name']?.toString() ?? '',
                              username: '@${_users[index]['username'] ?? ''}',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    final label = widget.type == UserListType.followers
        ? 'No followers yet'
        : 'Not following anyone yet';
    final sub = widget.type == UserListType.followers
        ? 'When people follow ${widget.ownerName}, they\'ll appear here'
        : '${widget.ownerName} hasn\'t followed anyone yet';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.type == UserListType.followers
                  ? Icons.group_outlined
                  : Icons.person_add_outlined,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(label, style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isFollowing;
  final String initials;
  final VoidCallback onFollowTap;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isFollowing,
    required this.initials,
    required this.onFollowTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name     = user['name']?.toString() ?? user['username']?.toString() ?? 'User';
    final username = '@${user['username'] ?? ''}';
    final school   = user['school']?.toString() ?? user['department']?.toString() ?? '';
    final followers = user['followers_count']?.toString() ??
        user['followers']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    school.isNotEmpty ? school : username,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (followers.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$followers followers',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.accentLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Follow / Following button
            GestureDetector(
              onTap: onFollowTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? AppColors.surface
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFollowing ? AppColors.borderMid : AppColors.accent,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFollowing ? AppColors.textSecondary : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
