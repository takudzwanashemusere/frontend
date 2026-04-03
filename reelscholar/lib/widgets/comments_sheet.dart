import 'package:flutter/material.dart';
import '../main.dart';

class CommentsSheet extends StatefulWidget {
  final String videoTitle;
  const CommentsSheet({super.key, required this.videoTitle});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _comments = [
    {
      'name': 'Rudo Chikwanda',
      'username': '@rudo_bio',
      'comment':
          'This actually helped me so much for my test tomorrow! Thank you',
      'time': '2m ago',
      'likes': 24,
      'isLiked': false,
    },
    {
      'name': 'Panashe Dzingira',
      'username': '@panashe_chem',
      'comment':
          'Can you do one on integration by parts next? That one confuses me',
      'time': '5m ago',
      'likes': 12,
      'isLiked': false,
    },
    {
      'name': 'Farai Mutasa',
      'username': '@farai_m',
      'comment':
          'Best explanation I have seen anywhere. CUT students are blessed to have this app!',
      'time': '12m ago',
      'likes': 47,
      'isLiked': true,
    },
    {
      'name': 'Tatenda Moyo',
      'username': '@tatenda_math',
      'comment': 'Glad it helped! Integration by parts coming next week',
      'time': '10m ago',
      'likes': 31,
      'isLiked': false,
      'isAuthor': true,
    },
    {
      'name': 'Simba Kowo',
      'username': '@simba_ict',
      'comment':
          'Shared this with my whole study group. We needed this before exams',
      'time': '18m ago',
      'likes': 8,
      'isLiked': false,
    },
    {
      'name': 'Chiedza Mupfumi',
      'username': '@chiedza_m',
      'comment':
          'Please do more on calculus! The lecturer moves too fast in class',
      'time': '25m ago',
      'likes': 19,
      'isLiked': false,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'name': 'You',
        'username': '@me',
        'comment': _commentController.text.trim(),
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });
    });
    _commentController.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
            child: ListView.builder(
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
                                Flexible(
                                  child: Text(
                                    c['name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
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
          ),

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
                  onTap: _addComment,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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

void showComments(BuildContext context, String videoTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(videoTitle: videoTitle),
  );
}
