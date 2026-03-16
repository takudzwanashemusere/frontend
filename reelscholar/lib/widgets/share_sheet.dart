import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

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
      {
        'label': 'WhatsApp',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF25D366),
      },
      {
        'label': 'Copy Link',
        'icon': Icons.link_rounded,
        'color': AppColors.accent,
      },
      {
        'label': 'Instagram',
        'icon': Icons.camera_alt_outlined,
        'color': const Color(0xFFE040FB),
      },
      {
        'label': 'Twitter/X',
        'icon': Icons.alternate_email_rounded,
        'color': const Color(0xFF1DA1F2),
      },
      {
        'label': 'Facebook',
        'icon': Icons.facebook_rounded,
        'color': const Color(0xFF1877F2),
      },
      {
        'label': 'Telegram',
        'icon': Icons.send_rounded,
        'color': const Color(0xFF00BCD4),
      },
    ];

    final List<Map<String, dynamic>> inAppOptions = [
      {
        'label': 'Send to Friend',
        'icon': Icons.person_add_outlined,
        'color': AppColors.accent,
      },
      {
        'label': 'Add to Playlist',
        'icon': Icons.playlist_add_rounded,
        'color': AppColors.accentLight,
      },
      {
        'label': 'Save Video',
        'icon': Icons.bookmark_outline_rounded,
        'color': AppColors.success,
      },
      {
        'label': 'Report',
        'icon': Icons.flag_outlined,
        'color': AppColors.error,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Share Video', style: AppTextStyles.headingMedium),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Video preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.accent,
                      size: 24,
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
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textTertiary,
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

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SHARE TO',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // External share icons
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: shareOptions.length,
              itemBuilder: (context, index) {
                final opt = shareOptions[index];
                final Color color = opt['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    if (opt['label'] == 'Copy Link') {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'https://reelscholar.cut.ac.zw/video/123',
                        ),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Link copied to clipboard',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt['label'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border),

          // In-app options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: inAppOptions.map((opt) {
                final Color color = opt['color'] as Color;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    opt['label'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onTap: () => Navigator.pop(context),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

void showShareSheet(BuildContext context, String videoTitle, String author) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ShareSheet(videoTitle: videoTitle, author: author),
  );
}
