import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/websocket_service.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Formats an ISO/SQLite timestamp as "2m ago", "Yesterday", etc.
String _relativeTime(String? ts) {
  if (ts == null || ts.isEmpty) return '';
  try {
    final dt = DateTime.parse(ts.contains('T') ? ts : ts.replaceFirst(' ', 'T'));
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  } catch (_) {
    return '';
  }
}

/// Formats an ISO/SQLite timestamp as HH:MM.
String _clockTime(String? ts) {
  if (ts == null || ts.isEmpty) return '';
  try {
    final dt = DateTime.parse(ts.contains('T') ? ts : ts.replaceFirst(' ', 'T'));
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

bool _isOnline(dynamic v) => v == true || v == 1;

// ─── Messages Screen ──────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeWs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Ensure WebSocket is connected
      final token = await AuthService.getToken();
      if (token != null) WebSocketService().connect(token);

      final convs = await MessagingService.getConversations();
      if (mounted) setState(() => _conversations = convs);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load messages');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'message') {
        _onWsMessage(event);
      } else if (event['type'] == 'status') {
        _onWsStatus(event);
      }
    });
  }

  void _onWsMessage(Map<String, dynamic> event) {
    final convId = event['conversation_id'];
    setState(() {
      final idx = _conversations.indexWhere((c) => c['conversation_id'] == convId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(_conversations[idx]);
        updated['last_message'] = event['text'];
        updated['last_message_at'] = event['created_at'];
        // Only increment unread if the message is from the other person
        if (event['is_mine'] == false) {
          updated['unread_count'] = (updated['unread_count'] as int? ?? 0) + 1;
        }
        _conversations.removeAt(idx);
        _conversations.insert(0, updated);
      }
    });
  }

  void _onWsStatus(Map<String, dynamic> event) {
    final userId = event['user_id'];
    setState(() {
      final idx = _conversations.indexWhere((c) => c['other_user_id'] == userId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(_conversations[idx]);
        updated['other_is_online'] = event['is_online'] == true;
        _conversations[idx] = updated;
      }
    });
  }

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _conversations
      : _conversations.where((c) {
          final name = c['other_name']?.toString().toLowerCase() ?? '';
          final user = c['other_username']?.toString().toLowerCase() ?? '';
          final q = _query.toLowerCase();
          return name.contains(q) || user.contains(q);
        }).toList();

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
        title: Text(
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
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search conversations...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 18,
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
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
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Online strip
                    if (_query.isEmpty) ...[
                      const SizedBox(height: 14),
                      _buildOnlineStrip(),
                      Divider(color: AppColors.border),
                    ] else
                      const SizedBox(height: 8),

                    // Conversation list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: _filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _conversations.isEmpty
                                      ? 'No conversations yet'
                                      : 'No conversations found',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  color: AppColors.border,
                                  indent: 72,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildConvTile(_filtered[index]);
                                },
                              ),
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

  Widget _buildOnlineStrip() {
    final online =
        _conversations.where((c) => _isOnline(c['other_is_online'])).toList();
    if (online.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: online.length,
        itemBuilder: (context, index) {
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
                          (person['other_name'] ?? '?')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
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
                            border:
                                Border.all(color: AppColors.bg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    (person['other_name'] ?? '').toString().split(' ')[0],
                    style: TextStyle(
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
    );
  }

  Widget _buildConvTile(Map<String, dynamic> conv) {
    final int unread = (conv['unread_count'] as int?) ?? 0;
    final bool online = _isOnline(conv['other_is_online']);
    final String name = conv['other_name'] ?? '';
    final String lastMsg = conv['last_message'] ?? '';
    final String time = _relativeTime(conv['last_message_at']);

    return GestureDetector(
      onTap: () => _openChat(context, conv),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (online)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
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
                          lastMsg,
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
                          decoration: BoxDecoration(
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
  }

  void _openChat(BuildContext context, Map<String, dynamic> conv) {
    // Clear unread count locally
    final idx = _conversations
        .indexWhere((c) => c['conversation_id'] == conv['conversation_id']);
    if (idx != -1) {
      setState(() {
        final updated = Map<String, dynamic>.from(_conversations[idx]);
        updated['unread_count'] = 0;
        _conversations[idx] = updated;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv['conversation_id'] as int,
          otherUserId: conv['other_user_id'] as int,
          otherName: conv['other_name'] ?? '',
          otherUsername: conv['other_username'] ?? '',
          initialIsOnline: _isOnline(conv['other_is_online']),
        ),
      ),
    ).then((_) => _loadConversations()); // refresh on return
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherName;
  final String otherUsername;
  final bool initialIsOnline;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherUsername,
    required this.initialIsOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  late bool _isOnline;

  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialIsOnline;
    _loadMessages();
    _subscribeWs();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await MessagingService.getMessages(widget.conversationId);
      if (mounted) setState(() => _messages = msgs);
    } catch (_) {
      // keep empty list, user can still send
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'message' &&
          event['conversation_id'] == widget.conversationId) {
        setState(() => _messages.add(event));
        _scrollToBottom();
      } else if (event['type'] == 'status' &&
          event['user_id'] == widget.otherUserId) {
        setState(() => _isOnline = event['is_online'] == true);
      }
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    // Send via WebSocket — the server echoes it back so it appears in the stream
    WebSocketService().sendMessage(widget.conversationId, text);
    _msgController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    widget.otherName.isNotEmpty
                        ? widget.otherName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color:
                          _isOnline ? AppColors.success : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.videocam_outlined,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMine = msg['is_mine'] == true;
                      return _buildMessage(msg, isMine);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
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
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
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
                    decoration: BoxDecoration(
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
    final text = msg['text']?.toString() ?? '';
    final time = _clockTime(msg['created_at']?.toString());

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
                widget.otherName.isNotEmpty
                    ? widget.otherName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
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
                  border:
                      isMine ? null : Border.all(color: AppColors.border),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isMine ? Colors.white : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
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
