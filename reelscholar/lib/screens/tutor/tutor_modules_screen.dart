import 'package:flutter/material.dart';
import '../../services/tutor_service.dart';
import 'tutor_chat_screen.dart';

const _kNavBg   = Color(0xFF0A1628);
const _kTopBar  = Color(0xFF1A3D7C);
const _kCardBg  = Color(0xFF0F2040);
const _kDivider = Color(0xFF1E3A6E);
const _kBlue    = Color(0xFF4A9EF5);
const _kOrange  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF34C759);

class TutorModulesScreen extends StatefulWidget {
  const TutorModulesScreen({super.key});

  @override
  State<TutorModulesScreen> createState() => _TutorModulesScreenState();
}

class _TutorModulesScreenState extends State<TutorModulesScreen> {
  bool _loading = true;
  String? _error;
  // Grouped data: { 'Year 1 - Semester 1': [ moduleMap, ... ], ... }
  Map<String, List<Map<String, dynamic>>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await TutorService.getModules();
      _parseAndGroup(data);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _parseAndGroup(dynamic data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // API may return a map keyed by year/semester, or a flat list, or a nested map
    if (data is Map) {
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is List) {
          grouped[key] = val
              .map((e) => Map<String, dynamic>.from(e as Map? ?? {}))
              .toList();
        } else if (val is Map) {
          // Nested: { 'Semester 1': [...], 'Semester 2': [...] }
          for (final sub in val.entries) {
            final subKey = '$key — ${sub.key}';
            final subVal = sub.value;
            if (subVal is List) {
              grouped[subKey] = subVal
                  .map((e) => Map<String, dynamic>.from(e as Map? ?? {}))
                  .toList();
            }
          }
        }
      }
    } else if (data is List) {
      // Flat list — group by year_level + semester fields
      for (final item in data) {
        final m = Map<String, dynamic>.from(item as Map? ?? {});
        final year = m['year_level'] ?? m['year'] ?? '?';
        final sem  = m['semester'] ?? '?';
        final key  = 'Year $year — Semester $sem';
        grouped.putIfAbsent(key, () => []).add(m);
      }
    }

    if (mounted) setState(() => _grouped = grouped);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expired. Please log in again.';
    if (msg.contains('SocketException') || msg.contains('network'))
      return 'No internet connection.';
    return 'Failed to load modules. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavBg,
      appBar: AppBar(
        backgroundColor: _kTopBar,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'AI Tutor',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kBlue),
      );
    }

    if (_error != null) {
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
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
                child: const Text('Retry',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
    }

    if (_grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: _kBlue.withOpacity(0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No modules found for your programme.\nMake sure your profile is complete.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _kBlue,
      backgroundColor: _kCardBg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _TutorBanner(),
          const SizedBox(height: 20),
          for (final entry in _grouped.entries) ...[
            _GroupHeader(label: entry.key),
            const SizedBox(height: 10),
            for (final module in entry.value)
              _ModuleCard(
                module: module,
                onTap: () => _openChat(module),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  void _openChat(Map<String, dynamic> module) {
    final id   = module['id']?.toString() ?? '';
    final name = module['name']?.toString() ??
        module['title']?.toString() ??
        module['module_name']?.toString() ??
        'Module';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module ID not found')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorChatScreen(moduleId: id, moduleName: name),
      ),
    ).then((_) => _load()); // refresh progress on return
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _TutorBanner extends StatelessWidget {
  const _TutorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3D7C), Color(0xFF0D2550)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: _kBlue, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Learn your modules with an AI study buddy. Pick a module to start or resume a session.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white60,
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

// ─── Group header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Module card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = module['name']?.toString() ??
        module['title']?.toString() ??
        module['module_name']?.toString() ??
        'Unknown Module';

    final code = module['code']?.toString() ??
        module['module_code']?.toString() ?? '';

    // Progress can come as 'progress', 'progress_percentage', or inside a 'progress' map
    final progress = _parseProgress(module);
    final status   = _parseStatus(module);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _kBlue,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: _kDivider,
                      color: progress >= 1.0
                          ? _kGreen
                          : progress > 0
                              ? _kBlue
                              : _kDivider,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  status == 'completed'
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_rounded,
                  color: status == 'completed' ? _kGreen : _kBlue,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  status == 'completed'
                      ? 'Completed — review again'
                      : status == 'in_progress'
                          ? 'Resume session'
                          : 'Start session',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: status == 'completed' ? _kGreen : _kBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _parseProgress(Map<String, dynamic> m) {
    // Try flat 'progress_percentage' first (e.g. "75.0" or 75)
    final flat = m['progress_percentage'] ?? m['progress'];
    if (flat != null) {
      if (flat is num) return (flat / 100).clamp(0.0, 1.0);
      if (flat is String) {
        final n = double.tryParse(flat.replaceAll('%', ''));
        if (n != null) return (n / 100).clamp(0.0, 1.0);
      }
      if (flat is Map) {
        final pp = flat['progress_percentage'];
        if (pp != null) {
          if (pp is num) return (pp / 100).clamp(0.0, 1.0);
          if (pp is String) {
            final n = double.tryParse(pp.replaceAll('%', ''));
            if (n != null) return (n / 100).clamp(0.0, 1.0);
          }
        }
      }
    }
    return 0.0;
  }

  String _parseStatus(Map<String, dynamic> m) {
    final s = m['status']?.toString() ??
        (m['progress'] is Map ? m['progress']['status']?.toString() : null) ??
        '';
    return s;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = _kGreen;
        label = 'Done';
        break;
      case 'in_progress':
        color = _kOrange;
        label = 'In Progress';
        break;
      default:
        color = Colors.white24;
        label = 'Not Started';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
