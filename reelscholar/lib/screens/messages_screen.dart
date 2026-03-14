import 'package:flutter/material.dart';

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
      'lastMessage': 'Thanks for the feedback on my video! 🙏',
      'time': '2m ago',
      'unread': 3,
      'isOnline': true,
      'color': const Color(0xFF6C63FF),
    },
    {
      'name': 'Rudo Chikwanda',
      'username': '@rudo_biology',
      'lastMessage': 'Can you explain DNA replication again?',
      'time': '15m ago',
      'unread': 1,
      'isOnline': true,
      'color': const Color(0xFF2ECC71),
    },
    {
      'name': 'Simba Kowo',
      'username': '@simba_ict',
      'lastMessage': 'Great video on Flutter! Very helpful 👏',
      'time': '1h ago',
      'unread': 0,
      'isOnline': false,
      'color': const Color(0xFFFF6B35),
    },
    {
      'name': 'Panashe Dzingira',
      'username': '@panashe_chem',
      'lastMessage': 'Are you coming to the study group tomorrow?',
      'time': '3h ago',
      'unread': 0,
      'isOnline': false,
      'color': const Color(0xFFE040FB),
    },
    {
      'name': 'Farai Mutasa',
      'username': '@farai_m',
      'lastMessage': 'Sent you a note on thermodynamics',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'color': const Color(0xFFFFD700),
    },
    {
      'name': 'Chiedza Mupfumi',
      'username': '@chiedza_m',
      'lastMessage': 'You: Sure, see you at the library!',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
      'color': const Color(0xFF00BCD4),
    },
  ];

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _conversations
      : _conversations
          .where((c) =>
              c['name'].toString().toLowerCase().contains(_query.toLowerCase()) ||
              c['username'].toString().toLowerCase().contains(_query.toLowerCase()))
          .toList();

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + (c['unread'] as int));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text(
          'Messages',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF6C63FF), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Online friends strip
          if (_query.isEmpty) ...[
            SizedBox(
              height: 90,
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
                  final Color color = person['color'] as Color;
                  return GestureDetector(
                    onTap: () => _openChat(context, person),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: color.withValues(alpha: 0.2),
                                child: Text(
                                  person['name'].toString().substring(0, 1),
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ),
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF0A0A0F),
                                        width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            person['name'].toString().split(' ')[0],
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
          ],

          // Conversations list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('No conversations found',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 14)),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final conv = _filtered[index];
                      final Color color = conv['color'] as Color;
                      final int unread = conv['unread'] as int;
                      final bool isOnline = conv['isOnline'] as bool;

                      return GestureDetector(
                        onTap: () => _openChat(context, conv),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        color.withValues(alpha: 0.2),
                                    child: Text(
                                      conv['name']
                                          .toString()
                                          .substring(0, 1),
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18),
                                    ),
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2ECC71),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: const Color(0xFF0A0A0F),
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Content
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
                                            color: unread > 0
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: unread > 0
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          conv['time'],
                                          style: TextStyle(
                                            color: unread > 0
                                                ? const Color(0xFF6C63FF)
                                                : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: unread > 0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conv['lastMessage'],
                                            style: TextStyle(
                                              color: unread > 0
                                                  ? Colors.white60
                                                  : Colors.white30,
                                              fontSize: 13,
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
                                              color: Color(0xFF6C63FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$unread',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
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

      // New message FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> person) {
    // Mark as read
    setState(() {
      final index = _conversations.indexWhere(
          (c) => c['username'] == person['username']);
      if (index != -1) _conversations[index]['unread'] = 0;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(person: person)),
    );
  }
}

// ─────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────

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
    {'text': 'Hey! Loved your latest video 🔥', 'isMine': false, 'time': '10:20'},
    {'text': 'Thank you so much! Still practicing 😅', 'isMine': true, 'time': '10:21'},
    {'text': 'Can you do one on integration next?', 'isMine': false, 'time': '10:22'},
    {'text': 'Yes definitely! Working on it this weekend', 'isMine': true, 'time': '10:23'},
    {'text': 'Amazing! You explain things so clearly 👏', 'isMine': false, 'time': '10:25'},
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
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
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
    final Color color = widget.person['color'] as Color;
    final bool isOnline = widget.person['isOnline'] as bool;

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
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    widget.person['name'].toString().substring(0, 1),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0A0A0F), width: 1.5),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                      color: isOnline
                          ? const Color(0xFF2ECC71)
                          : Colors.white38,
                      fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined,
                color: Colors.white70, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined,
                color: Colors.white70, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final bool isMine = msg['isMine'] as bool;
                return _buildMessage(msg, isMine, color);
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined,
                              color: Colors.white38, size: 20),
                          onPressed: () {},
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
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
      Map<String, dynamic> msg, bool isMine, Color otherColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: otherColor.withValues(alpha: 0.2),
              child: Text(
                widget.person['name'].toString().substring(0, 1),
                style: TextStyle(
                    color: otherColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
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
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: Text(
                  msg['text'],
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                msg['time'],
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}