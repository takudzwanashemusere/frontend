import 'package:flutter/material.dart';
import '../main.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';

class CommentsSheet extends StatefulWidget {
  final String videoTitle;
  final dynamic videoId;
  const CommentsSheet({super.key, required this.videoTitle, this.videoId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (widget.videoId == null) return;
    setState(() => _isLoading = true);
    try {
      final list = await VideoService.getComments(widget.videoId);
      if (mounted) {
        setState(() {
          _comments = list.map(_normalizeComment).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _normalizeComment(Map<String, dynamic> c) {
    final user = (c['user'] is Map) ? c['user'] as Map<String, dynamic> : <String, dynamic>{};
    return {
      'id': c['id'],
      'name': user['name'] ?? c['author_name'] ?? 'Unknown',
      'username': '@${user['username'] ?? c['username'] ?? 'user'}',
      'comment': c['body'] ?? c['comment'] ?? c['content'] ?? '',
      'time': c['created_at']?.toString() ?? '',
      'likes': (c['likes_count'] ?? c['likes'] ?? 0) as int? ?? 0,
      'isLiked': c['is_liked'] == true,
      'isAuthor': c['is_author'] == true,
    };
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (widget.videoId == null) return;

    setState(() => _isPosting = true);
    _commentController.clear();

    try {
      final raw = await VideoService.postComment(widget.videoId, text);
      final comment = raw.isNotEmpty
          ? _normalizeComment(raw)
          : {
              'id': null,
              'name': await AuthService.getUserName() ?? 'You',
              'username': '@${await AuthService.getUsername() ?? 'me'}',
              'comment': text,
              'time': 'Just now',
              'likes': 0,
              'isLiked': false,
            };
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _isPosting = false;
        });
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.borderMid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: AppTextStyles.headingMedium,
                    ),
                    Text(
                      '${_comments.length} comments',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 16),

          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Be the first!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                final bool isLiked = c['isLiked'] as bool;
                final bool isAuthor = c['isAuthor'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text(
                          c['name'].toString().substring(0, 1),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c['name'],
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isAuthor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Author',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Text(
                                  c['time'],
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['comment'],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _comments[index]['isLiked'] = !isLiked;
                                      _comments[index]['likes'] = isLiked
                                          ? c['likes'] - 1
                                          : c['likes'] + 1;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 13,
                                        color: isLiked
                                            ? AppColors.error
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${c['likes']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: isLiked
                                              ? AppColors.error
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    'Reply',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),  // end Expanded

          // Comment input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    'Y',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isPosting ? null : _addComment,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: _isPosting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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

void showComments(BuildContext context, String videoTitle, {dynamic videoId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(videoTitle: videoTitle, videoId: videoId),
  );
}
