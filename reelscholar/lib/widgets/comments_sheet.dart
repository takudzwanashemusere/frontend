import 'package:flutter/material.dart';

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
      'comment': 'This actually helped me so much for my test tomorrow! Thank you 🙏',
      'time': '2m ago',
      'likes': 24,
      'isLiked': false,
      'color': const Color(0xFF2ECC71),
    },
    {
      'name': 'Panashe Dzingira',
      'username': '@panashe_chem',
      'comment': 'Can you do one on integration by parts next? That one confuses me 😅',
      'time': '5m ago',
      'likes': 12,
      'isLiked': false,
      'color': const Color(0xFFE040FB),
    },
    {
      'name': 'Farai Mutasa',
      'username': '@farai_m',
      'comment': 'Best explanation I have seen on YouTube or anywhere. CUT students are blessed to have this app!',
      'time': '12m ago',
      'likes': 47,
      'isLiked': true,
      'color': const Color(0xFFFFD700),
    },
    {
      'name': 'Tatenda Moyo',
      'username': '@tatenda_math',
      'comment': 'Glad it helped! Integration by parts coming next week 🔥',
      'time': '10m ago',
      'likes': 31,
      'isLiked': false,
      'color': const Color(0xFF6C63FF),
      'isAuthor': true,
    },
    {
      'name': 'Simba Kowo',
      'username': '@simba_ict',
      'comment': 'Shared this with my whole study group. We needed this before exams 📚',
      'time': '18m ago',
      'likes': 8,
      'isLiked': false,
      'color': const Color(0xFFFF6B35),
    },
    {
      'name': 'Chiedza Mupfumi',
      'username': '@chiedza_m',
      'comment': 'Please do more on calculus! The lecturer moves too fast in class 😭',
      'time': '25m ago',
      'likes': 19,
      'isLiked': false,
      'color': const Color(0xFF00BCD4),
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
        'color': const Color(0xFF6C63FF),
      });
    });
    _commentController.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_comments.length} comments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 22),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 20),

          // Comments list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                final Color color = c['color'] as Color;
                final bool isLiked = c['isLiked'] as bool;
                final bool isAuthor = c['isAuthor'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Text(
                          c['name'].toString().substring(0, 1),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Comment content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isAuthor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Author',
                                      style: TextStyle(
                                        color: Color(0xFF6C63FF),
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
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['comment'],
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.4,
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
                                        size: 14,
                                        color: isLiked
                                            ? Colors.redAccent
                                            : Colors.white38,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${c['likes']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isLiked
                                              ? Colors.redAccent
                                              : Colors.white38,
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
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.35),
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
              color: const Color(0xFF0A0A0F),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF6C63FF),
                  child: Text(
                    'Y',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
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

// Helper function to show comments from anywhere
void showComments(BuildContext context, String videoTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(videoTitle: videoTitle),
  );
}