import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerWidget extends StatefulWidget {
  final String? filePath;
  final String? networkUrl;
  final List<int>? fileBytes;

  const VideoPlayerWidget({
    super.key,
    this.filePath,
    this.networkUrl,
    this.fileBytes,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.fileBytes != null && widget.fileBytes!.isNotEmpty) {
        setState(() => _hasError = true);
        return;
      } else if (widget.filePath != null) {
        _controller = VideoPlayerController.file(File(widget.filePath!));
      } else if (widget.networkUrl != null) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.networkUrl!),
        );
      } else {
        setState(() => _hasError = true);
        return;
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller!.play() : _controller!.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileBytes != null && widget.fileBytes!.isNotEmpty) {
      return _buildWebReadyPlaceholder();
    }

    if (_hasError || _controller == null) {
      return _buildPlaceholder();
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
          strokeWidth: 2,
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF6C63FF),
                backgroundColor: Colors.white24,
                bufferedColor: Colors.white38,
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebReadyPlaceholder() {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    width: 2),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF6C63FF), size: 40),
            ),
            const SizedBox(height: 14),
            const Text('Video uploaded ✓',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text('Plays on Android device',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text('Video unavailable',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}