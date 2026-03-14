import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/video_store.dart';

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

  String? _selectedSchool;
  String? _selectedModule;
  bool _hasVideo = false;
  String _selectedFileName = '';
  String? _filePath;
  List<int>? _fileBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // CUT Schools and their modules
  final Map<String, List<String>> _schoolModules = {
    'School of Natural Sciences and Mathematics': [
      'Calculus',
      'Linear Algebra',
      'Statistics & Probability',
      'Discrete Mathematics',
      'Organic Chemistry',
      'Analytical Chemistry',
      'Classical Physics',
      'Quantum Mechanics',
    ],
    'School of Engineering Science and Technology': [
      'Software Engineering',
      'Computer Science',
      'ICT & Networking',
      'Electronics Engineering',
      'Civil Engineering',
      'Mechanical Engineering',
      'Database Systems',
      'Artificial Intelligence',
    ],
    'School of Entrepreneurship and Business Sciences': [
      'Business Management',
      'Accounting & Finance',
      'Economics',
      'Marketing Management',
      'Human Resource Management',
      'Strategic Management',
      'Entrepreneurship',
      'Supply Chain Management',
    ],
    'School of Agriculture Sciences and Technology': [
      'Crop Science',
      'Animal Science',
      'Agronomy',
      'Agricultural Economics',
      'Soil Science',
      'Horticulture',
      'Agricultural Engineering',
      'Post-Harvest Technology',
    ],
    'School of Wildlife and Environmental Science': [
      'Wildlife Management',
      'Ecology & Conservation',
      'Environmental Science',
      'Tourism & Wildlife',
      'Forest Management',
      'Environmental Policy',
      'Animal Behaviour',
      'GIS & Remote Sensing',
    ],
    'School of Health Sciences and Technology': [
      'Nursing Science',
      'Public Health',
      'Biomedical Science',
      'Pharmacy',
      'Environmental Health',
      'Medical Laboratory',
      'Nutrition & Dietetics',
      'Health Informatics',
    ],
    'School of Hospitality and Tourism': [
      'Hotel Management',
      'Tourism Management',
      'Food & Beverage Management',
      'Events Management',
      'Travel & Tourism',
      'Hospitality Operations',
      'Culinary Arts',
      'Resort Management',
    ],
    'School of Art and Design': [
      'Graphic Design',
      'Visual Arts',
      'Digital Media',
      'Fine Arts',
      'Interior Design',
      'Fashion Design',
      'Photography',
      'Animation & Film',
    ],
  };

  List<String> get _modules =>
      _selectedSchool != null ? _schoolModules[_selectedSchool!]! : [];

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

  void _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _hasVideo = true;
          _selectedFileName = file.name;
          _filePath = file.path;
          _fileBytes =
              file.bytes != null ? List<int>.from(file.bytes!) : null;
        });
      }
    } catch (e) {
      setState(() {
        _hasVideo = true;
        _selectedFileName = 'selected_video.mp4';
        _filePath = null;
        _fileBytes = null;
      });
    }
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
    if (_selectedSchool == null) {
      _showSnack('Please select your school', Colors.redAccent);
      return;
    }
    if (_selectedModule == null) {
      _showSnack('Please select a module', Colors.redAccent);
      return;
    }

    setState(() => _isUploading = true);

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _uploadProgress = i / 100);
    }

    VideoStore.addVideo({
      'username': '@me',
      'name': 'You',
      'school': _selectedSchool,
      'subject': _selectedModule,
      'title': _titleController.text.trim(),
      'likes': '0',
      'comments': '0',
      'shares': '0',
      'color': 0xFF1A1040,
      'accent': 0xFF6C63FF,
      'filePath': _filePath,
      'fileBytes': _fileBytes,
    });

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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _handleUpload,
              child: const Text('Post',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
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
                        height: 180,
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
                          ),
                        ),
                        child: _hasVideo
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF6C63FF), size: 44),
                                  const SizedBox(height: 10),
                                  const Text('Video selected!',
                                      style: TextStyle(
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(_selectedFileName,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          fontSize: 12)),
                                  TextButton(
                                    onPressed: _pickVideo,
                                    child: const Text('Change video',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.video_call_rounded,
                                        color: Color(0xFF6C63FF),
                                        size: 30),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Tap to select video',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('MP4, MOV — max 60 seconds',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.35),
                                          fontSize: 12)),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    _buildLabel('Video Title *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                        controller: _titleController,
                        hint: 'e.g. Introduction to Crop Rotation',
                        maxLines: 1),

                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    _buildTextField(
                        controller: _descController,
                        hint: 'What will students learn from this video?',
                        maxLines: 3),

                    const SizedBox(height: 20),

                    // School dropdown
                    _buildLabel('School *'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedSchool,
                      hint: 'Select your school',
                      icon: Icons.school_outlined,
                      items: _schoolModules.keys.toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSchool = val;
                          _selectedModule = null; // reset module
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Module dropdown
                    _buildLabel('Module *'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedModule,
                      hint: _selectedSchool == null
                          ? 'Select a school first'
                          : 'Select module',
                      icon: Icons.menu_book_outlined,
                      items: _modules,
                      enabled: _selectedSchool != null,
                      onChanged: (val) =>
                          setState(() => _selectedModule = val),
                    ),

                    const SizedBox(height: 24),

                    // Guidelines
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFD700)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFFFD700), size: 16),
                              SizedBox(width: 6),
                              Text('Content Guidelines',
                                  style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...[
                            'Videos must be relevant to your CUT module',
                            'Maximum duration: 60 seconds',
                            'No offensive or inappropriate content',
                            'Content will be reviewed before publishing',
                          ].map((rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                    Expanded(
                                      child: Text(rule,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              fontSize: 12,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(Icons.upload_rounded, size: 20),
                        label: const Text('Upload Video',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
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
              child: const Icon(Icons.cloud_upload_rounded,
                  color: Color(0xFF6C63FF), size: 48),
            ),
            const SizedBox(height: 28),
            const Text('Uploading your video...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Please keep the app open',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13)),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6C63FF)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70));
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
            color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1A1A2E) : const Color(0xFF111118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A2E),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white38),
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        ),
        hint: Text(hint,
            style: TextStyle(
                color: Colors.white.withValues(alpha: enabled ? 0.25 : 0.15),
                fontSize: 14)),
        items: items
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}