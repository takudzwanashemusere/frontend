import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareSheet extends StatelessWidget {
  final String videoTitle;
  final String author;

  const ShareSheet({
    super.key,
    required this.videoTitle,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shareOptions = [
      {'label': 'WhatsApp', 'icon': Icons.chat_rounded, 'color': const Color(0xFF25D366)},
      {'label': 'Copy Link', 'icon': Icons.link_rounded, 'color': const Color(0xFF6C63FF)},
      {'label': 'Instagram', 'icon': Icons.camera_alt_outlined, 'color': const Color(0xFFE040FB)},
      {'label': 'Twitter/X', 'icon': Icons.alternate_email_rounded, 'color': const Color(0xFF1DA1F2)},
      {'label': 'Facebook', 'icon': Icons.facebook_rounded, 'color': const Color(0xFF1877F2)},
      {'label': 'Telegram', 'icon': Icons.send_rounded, 'color': const Color(0xFF00BCD4)},
    ];

    final List<Map<String, dynamic>> inAppOptions = [
      {'label': 'Send to Friend', 'icon': Icons.person_add_outlined, 'color': const Color(0xFF6C63FF)},
      {'label': 'Add to Playlist', 'icon': Icons.playlist_add_rounded, 'color': const Color(0xFFFFD700)},
      {'label': 'Save Video', 'icon': Icons.bookmark_outline_rounded, 'color': const Color(0xFF2ECC71)},
      {'label': 'Report', 'icon': Icons.flag_outlined, 'color': Colors.redAccent},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Video',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 22),
                ),
              ],
            ),
          ),

          // Video preview card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF6C63FF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Share to section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share to',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // External share options
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shareOptions.length,
              itemBuilder: (context, index) {
                final opt = shareOptions[index];
                final Color color = opt['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    if (opt['label'] == 'Copy Link') {
                      Clipboard.setData(
                        const ClipboardData(
                            text: 'https://reelscholar.cut.ac.zw/video/123'),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link copied to clipboard!'),
                          backgroundColor: const Color(0xFF6C63FF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt['label'],
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.08)),

          // In-app options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: inAppOptions.map((opt) {
                final Color color = opt['color'] as Color;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(opt['icon'] as IconData, color: color, size: 20),
                  ),
                  title: Text(
                    opt['label'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24, size: 20),
                  onTap: () => Navigator.pop(context),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Helper to show share sheet
void showShareSheet(BuildContext context, String videoTitle, String author) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ShareSheet(videoTitle: videoTitle, author: author),
  );
}