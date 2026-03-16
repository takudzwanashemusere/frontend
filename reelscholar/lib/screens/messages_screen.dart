import 'package:flutter/material.dart';
import '../main.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Tatenda Moyo',
      'username': '@tatenda_math',
      'lastMessage': 'Thanks for the feedback on my video!',
      'time': '2m ago',
      'unread': 3,
      'isOnline': true,
    },
    {
      'name': 'Rudo Chikwanda',
      'username': '@rudo_biology',
      'lastMessage': 'Can you explain DNA replication again?',
      'time': '15m ago',
      'unread': 1,
      'isOnline': true,
    },
    {
      'name': 'Simba Kowo',
      'username': '@simba_ict',
      'lastMessage': 'Great video on Flutter! Very helpful',
      'time': '1h ago',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'Panashe Dzingira',
      'username': '@panashe_chem',
      'lastMessage': 'Are you coming to the study group tomorrow?',
      'time': '3h ago',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'Farai Mutasa',
      'username': '@farai_m',
      'lastMessage': 'Sent you a note on thermodynamics',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'Chiedza Mupfumi',
      'username': '@chiedza_m',
      'lastMessage': 'You: Sure, see you at the library!',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
    },
  ];

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _conversations
      : _conversations
          .where((c) =>
              c['name']
                  .toString()
                  .toLowerCase()
                  .contains(_query.toLowerCase()) ||
              c['username']
                  .toString()
                  .toLowerCase()
                  .contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textTertiary,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Online strip
          if (_query.isEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _conversations
                    .where((c) => c['isOnline'] == true)
                    .length,
                itemBuilder: (context, index) {
                  final online = _conversations
                      .where((c) => c['isOnline'] == true)
                      .toList();
                  final person = online[index];
                  return GestureDetector(
                    onTap: () => _openChat(context, person),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.surface,
                                child: Text(
                                  person['name'].toString().substring(0, 1),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.bg,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            person['name'].toString().split(' ')[0],
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
            const Divider(color: AppColors.border),
          ] else
            const SizedBox(height: 8),

          // Conversations
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.border,
                      indent: 72,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final conv = _filtered[index];
                      final int unread = conv['unread'] as int;
                      final bool isOnline = conv['isOnline'] as bool;

                      return GestureDetector(
                        onTap: () => _openChat(context, conv),
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.surface,
                                    child: Text(
                                      conv['name']
                                          .toString()
                                          .substring(0, 1),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.bg,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          conv['name'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: unread > 0
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                            fontWeight: unread > 0
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          conv['time'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: unread > 0
                                                ? AppColors.accent
                                                : AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: unread > 0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conv['lastMessage'],
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: unread > 0
                                                  ? AppColors.textSecondary
                                                  : AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unread > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: AppColors.accent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$unread',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        elevation: 2,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> person) {
    setState(() {
      final index = _conversations
          .indexWhere((c) => c['username'] == person['username']);
      if (index != -1) _conversations[index]['unread'] = 0;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(person: person)),
    );
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> person;
  const ChatScreen({super.key, required this.person});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! Loved your latest video', 'isMine': false, 'time': '10:20'},
    {
      'text': 'Thank you so much! Still practicing',
      'isMine': true,
      'time': '10:21'
    },
    {
      'text': 'Can you do one on integration next?',
      'isMine': false,
      'time': '10:22'
    },
    {
      'text': 'Yes definitely! Working on it this weekend',
      'isMine': true,
      'time': '10:23'
    },
    {
      'text': 'Amazing! You explain things so clearly',
      'isMine': false,
      'time': '10:25'
    },
  ];

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _msgController.text.trim(),
        'isMine': true,
        'time': TimeOfDay.now().format(context),
      });
    });
    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 80), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.person['isOnline'] as bool;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    widget.person['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.person['name'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isOnline ? AppColors.success : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam_outlined,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessage(msg, msg['isMine'] as bool);
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
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

  Widget _buildMessage(Map<String, dynamic> msg, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.surface,
              child: Text(
                widget.person['name'].toString().substring(0, 1),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                  border: isMine
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Text(
                  msg['text'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isMine
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                msg['time'],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
