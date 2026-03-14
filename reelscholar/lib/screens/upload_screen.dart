import 'package:flutter/material.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedSubject;
  bool _hasVideo = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _subjects = [
    'Mathematics',
    'Biology',
    'Chemistry',
    'Physics',
    'ICT',
    'English',
    'Accounting',
    'Engineering',
    'Business Studies',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickVideo() {
    // TODO: Connect to file_picker package for real video selection
    setState(() => _hasVideo = true);
  }

  void _handleUpload() async {
    if (!_hasVideo) {
      _showSnack('Please select a video first', Colors.redAccent);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please add a title', Colors.redAccent);
      return;
    }
    if (_selectedSubject == null) {
      _showSnack('Please select a subject', Colors.redAccent);
      return;
    }

    setState(() => _isUploading = true);

    // Simulate upload progress — replace with real API call
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _uploadProgress = i / 100);
    }

    setState(() => _isUploading = false);
    if (mounted) {
      _showSnack('Video uploaded successfully! 🎉', const Color(0xFF2ECC71));
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: const Text(
          'Upload Video',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _handleUpload,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? _buildUploadingView()
          : FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video picker
                    GestureDetector(
                      onTap: _pickVideo,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _hasVideo
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hasVideo
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withValues(alpha: 0.1),
                            width: _hasVideo ? 1.5 : 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: _hasVideo
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF6C63FF),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Video selected!',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'educational_video.mp4',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _pickVideo,
                                    child: const Text(
                                      'Change video',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.video_call_rounded,
                                      color: Color(0xFF6C63FF),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tap to select video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MP4, MOV — max 60 seconds',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title field
                    _buildLabel('Video Title *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g. Quadratic Equations in 60 seconds',
                      maxLines: 1,
                    ),

                    const SizedBox(height: 20),

                    // Description field
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descController,
                      hint:
                          'Briefly describe what students will learn from this video...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    // Subject dropdown
                    _buildLabel('Subject *'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white38),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.school_outlined,
                              color: Colors.white38, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                        ),
                        hint: Text(
                          'Select a subject',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 14,
                          ),
                        ),
                        items: _subjects.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSubject = val),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Guidelines card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFFFD700), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Content Guidelines',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...[
                            'Videos must be educational and CUT-relevant',
                            'Maximum duration: 60 seconds',
                            'No offensive or inappropriate content',
                            'Content will be reviewed before publishing',
                          ].map(
                            (rule) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      rule,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(Icons.upload_rounded, size: 20),
                        label: const Text(
                          'Upload Video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: Color(0xFF6C63FF),
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Uploading your video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please keep the app open',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}