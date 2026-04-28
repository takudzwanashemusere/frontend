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
      final convs = await MessagingService.getConversations();
      if (mounted) setState(() => _conversations = convs);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load messages: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().stream.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'message') {
        _onWsMessage(event);
      }
    });
  }

  void _onWsMessage(Map<String, dynamic> event) {
    final convId = event['id']?.toString() ?? event['conversation_id']?.toString();
    if (convId == null) return;
    setState(() {
      final idx = _conversations.indexWhere((c) => c['id']?.toString() == convId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(_conversations[idx]);
        updated['last_message_preview'] = event['body'] ?? event['text'];
        updated['last_message_at'] = event['created_at'];
        if (event['is_mine'] == false) {
          updated['unread_count'] = (updated['unread_count'] as int? ?? 0) + 1;
        }
        _conversations.removeAt(idx);
        _conversations.insert(0, updated);
      }
    });
  }

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _conversations
      : _conversations.where((c) {
          final otherUser =
              c['other_user'] is Map ? c['other_user'] as Map : {};
          final name =
              otherUser['full_name']?.toString().toLowerCase() ?? '';
          final q = _query.toLowerCase();
          return name.contains(q);
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
        onPressed: () => _showNewMessageSheet(context),
        backgroundColor: AppColors.accent,
        elevation: 2,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildConvTile(Map<String, dynamic> conv) {
    final int unread = (conv['unread_count'] as int?) ?? 0;
    final otherUser =
        conv['other_user'] is Map ? conv['other_user'] as Map : {};
    final String name = otherUser['full_name']?.toString() ?? '';
    final String lastMsg = conv['last_message_preview']?.toString() ?? '';
    final String time = _relativeTime(conv['last_message_at']?.toString());

    return GestureDetector(
      onTap: () => _openChat(context, conv),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
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

  void _showNewMessageSheet(BuildContext context) {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Future<void> search(String q) async {
            if (q.trim().isEmpty) {
              setSheet(() {
                results = [];
                searching = false;
              });
              return;
            }
            setSheet(() {
              searching = true;
              sheetError = null;
            });
            try {
              final r = await MessagingService.searchUsers(q.trim());
              setSheet(() {
                results = r;
                searching = false;
              });
            } catch (_) {
              setSheet(() {
                searching = false;
                sheetError = 'Search failed';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'New Message',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: search,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
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
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sheetError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child:
                          Text(sheetError!, style: AppTextStyles.bodyMedium),
                    ),
                  )
                else if (results.isEmpty && searchCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final user = results[i];
                        // New API uses full_name and uid
                        final name =
                            user['full_name']?.toString() ?? '';
                        final username =
                            user['username']?.toString() ?? '';
                        final uid = user['uid']?.toString() ?? '';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.surface,
                            child: Text(
                              name.isNotEmpty
                                  ? name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: username.isNotEmpty
                              ? Text(
                                  '@$username',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          onTap: () async {
                            Navigator.pop(ctx);
                            final nav = Navigator.of(context);
                            final messenger =
                                ScaffoldMessenger.of(context);
                            try {
                              final convId = await MessagingService
                                  .startConversation(uid);
                              if (!mounted) return;
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: convId,
                                    otherUserId: uid,
                                    otherName: name,
                                    otherUsername: username,
                                  ),
                                ),
                              ).then((_) => _loadConversations());
                            } catch (_) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Could not start conversation'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> conv) {
    // Clear unread count locally
    final convId = conv['id']?.toString() ?? '';
    final idx =
        _conversations.indexWhere((c) => c['id']?.toString() == convId);
    if (idx != -1) {
      setState(() {
        final updated = Map<String, dynamic>.from(_conversations[idx]);
        updated['unread_count'] = 0;
        _conversations[idx] = updated;
      });
    }

    final otherUser =
        conv['other_user'] is Map ? conv['other_user'] as Map : {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          otherUserId: otherUser['uid']?.toString() ?? '',
          otherName: otherUser['full_name']?.toString() ?? '',
          otherUsername: otherUser['username']?.toString() ?? '',
        ),
      ),
    ).then((_) => _loadConversations());
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String otherUsername;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherUsername,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _myUid;
  // Holds the actual conversation id once a new conversation is created
  late String _convId;

  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _convId = widget.conversationId;
    _loadMyUid();
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

  Future<void> _loadMyUid() async {
    final uid = await AuthService.getUserId();
    if (mounted) setState(() => _myUid = uid);
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await MessagingService.getMessages(_convId);
      if (mounted) setState(() => _messages = msgs);
    } catch (_) {
      // keep empty list — user can still send
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
      final eventConvId = event['id']?.toString() ??
          event['conversation_id']?.toString();
      if (event['type'] == 'message' && eventConvId == _convId) {
        setState(() => _messages.add(event));
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();

    try {
      final msg = await MessagingService.sendMessage(
        _convId,
        text,
        receiverUid: _convId.isEmpty ? widget.otherUserId : null,
      );
      if (mounted) {
        // If we just created a new conversation, update our local convId
        if (_convId.isEmpty) {
          final newConvId =
              msg['conversation_id']?.toString() ?? msg['id']?.toString() ?? '';
          if (newConvId.isNotEmpty) {
            setState(() => _convId = newConvId);
          }
        }
        // Build a local message representation for immediate display
        final localMsg = {
          'body': text,
          'created_at': DateTime.now().toIso8601String(),
          'is_mine': true,
          'sender': {'uid': _myUid},
          ...msg,
        };
        setState(() => _messages.add(localMsg));
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
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

  bool _isMine(Map<String, dynamic> msg) {
    if (msg['is_mine'] == true) return true;
    if (msg['is_mine'] == false) return false;
    final senderUid =
        (msg['sender'] is Map ? msg['sender'] as Map : {})['uid']?.toString();
    return senderUid != null && _myUid != null && senderUid == _myUid;
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (widget.otherUsername.isNotEmpty)
                  Text(
                    '@${widget.otherUsername}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
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
                : _messages.isEmpty && _convId.isEmpty
                    ? Center(
                        child: Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessage(msg, _isMine(msg));
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
    final text = msg['body']?.toString() ?? msg['text']?.toString() ?? '';
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
                    color:
                        isMine ? Colors.white : AppColors.textSecondary,
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
