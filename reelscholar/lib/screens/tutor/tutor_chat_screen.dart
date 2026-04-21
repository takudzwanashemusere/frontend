import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/tutor_service.dart';

const _kNavBg   = Color(0xFF0A1628);
const _kTopBar  = Color(0xFF1A3D7C);
const _kCardBg  = Color(0xFF0F2040);
const _kDivider = Color(0xFF1E3A6E);
const _kBlue    = Color(0xFF4A9EF5);
const _kOrange  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF34C759);

class TutorChatScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const TutorChatScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final _scrollController = ScrollController();
  final _inputController  = TextEditingController();

  // Each message: { 'role': 'user'|'assistant', 'content': String, 'timestamp': String? }
  final List<Map<String, dynamic>> _messages = [];

  bool _starting   = true;
  bool _sending    = false;
  bool _resetting  = false;
  String? _error;

  Map<String, dynamic>? _progress;

  @override
  void initState() {
    super.initState();
    _startOrResume();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // ─── API calls ──────────────────────────────────────────────────────────────

  Future<void> _startOrResume() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final res = await TutorService.startSession(widget.moduleId);
      _progress = res['progress'] as Map<String, dynamic>?;

      // Load existing history
      await _loadHistory();

      // If the API returns a greeting message include it
      final greeting = res['message']?.toString() ?? '';
      if (greeting.isNotEmpty && _messages.isEmpty) {
        _addMessage('assistant', greeting);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await TutorService.getHistory(widget.moduleId);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (final item in history) {
            final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            final role    = m['role']?.toString() ?? 'assistant';
            final content = m['content']?.toString() ??
                m['message']?.toString() ??
                m['text']?.toString() ?? '';
            if (content.isNotEmpty) _messages.add({'role': role, 'content': content});
          }
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Non-fatal: start fresh if history fails
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    _inputController.clear();
    _addMessage('user', text);
    setState(() => _sending = true);

    try {
      final res = await TutorService.chat(widget.moduleId, text);
      final reply    = res['message']?.toString() ?? '';
      final progress = res['progress'];
      if (progress is Map) {
        setState(() => _progress = Map<String, dynamic>.from(progress));
      }
      if (reply.isNotEmpty) _addMessage('assistant', reply);

      // Suggest quiz if flag is set
      if (_progress?['should_suggest_quiz'] == true) {
        _showQuizSuggestion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resetSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Reset Session?',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
        content: const Text(
          'This will clear the conversation and start fresh.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Reset', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _resetting = true);
    try {
      await TutorService.resetSession(widget.moduleId);
      setState(() {
        _messages.clear();
        _progress = null;
      });
      await _startOrResume();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _fetchAndShowQuiz() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kBlue)),
    );
    try {
      final quiz = await TutorService.getQuiz(widget.moduleId);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loader
      _showQuizDialog(quiz);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _addMessage(String role, String content) {
    if (mounted) {
      setState(() => _messages.add({'role': role, 'content': content}));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) return 'No active session. Starting a new one…';
      if (statusCode == 401) return 'Session expired. Please log in again.';
      if (statusCode == 404) return 'Module not found.';
    }
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _showQuizSuggestion() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'You\'re ready for a quiz!',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: _kGreen.withValues(alpha:0.9),
        action: SnackBarAction(
          label: 'Take Quiz',
          textColor: Colors.white,
          onPressed: _fetchAndShowQuiz,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showQuizDialog(Map<String, dynamic> quiz) {
    final quizId    = quiz['quiz_id']?.toString() ?? '';
    final title     = quiz['title']?.toString() ?? 'Quiz';
    final questions = quiz['questions'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(title,
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
        content: Text(
          quizId.isEmpty
              ? 'No quiz available yet for this module.'
              : 'Quiz ID: $quizId\n\nQuestions: ${questions ?? "N/A"}',
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _kBlue)),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavBg,
      appBar: _buildAppBar(),
      body: _starting
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    if (_progress != null) _ProgressBar(progress: _progress!),
                    Expanded(child: _buildMessages()),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kTopBar,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.moduleName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'AI Tutor Session',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.quiz_outlined, color: Colors.white),
          tooltip: 'Take Quiz',
          onPressed: _fetchAndShowQuiz,
        ),
        if (_resetting)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
            tooltip: 'Reset Session',
            onPressed: _resetSession,
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kOrange, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startOrResume,
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
              child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Session started. Ask anything about this module!',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Poppins', color: Colors.white38, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: _kCardBg,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ask the tutor…',
                hintStyle: const TextStyle(
                    fontFamily: 'Poppins', color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: _kNavBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBlue),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: _kBlue),
                  ),
                )
              : IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: _kBlue),
                  style: IconButton.styleFrom(
                    backgroundColor: _kBlue.withValues(alpha:0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final Map<String, dynamic> progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct         = progress['progress_percentage']?.toString() ?? '0%';
    final completed   = progress['topics_completed'] ?? 0;
    final total       = progress['total_topics'] ?? 0;
    final status      = progress['status']?.toString() ?? '';

    double frac = 0.0;
    final n = double.tryParse(pct.replaceAll('%', ''));
    if (n != null) frac = (n / 100).clamp(0.0, 1.0);

    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total topics',
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: Colors.white54),
              ),
              Text(
                pct,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kBlue),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: _kDivider,
              color: status == 'completed' ? _kGreen : _kBlue,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser  = message['role'] == 'user';
    final content = message['content']?.toString() ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _kBlue.withValues(alpha:0.9) : _kCardBg,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: _kDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Icon(Icons.psychology_rounded, color: _kBlue, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                content,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isUser ? Colors.white : Colors.white.withValues(alpha:0.9),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
