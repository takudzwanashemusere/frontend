import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/video_store.dart';
import '../main.dart';
import '../services/content_detection_service.dart';

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
  Uint8List? _fileBytes;
  int _fileSizeBytes = 0;
  bool _isUploading = false;
  bool _isValidating = false;
  double _uploadProgress = 0.0;
  String _validatingStatus = 'Checking content...';

  static const int _hardLimitBytes = 100 * 1024 * 1024; // 100 MB
  static const int _warnLimitBytes = 50 * 1024 * 1024;  // 50 MB

  String get _fileSizeLabel {
    if (_fileSizeBytes <= 0) return '';
    if (_fileSizeBytes >= 1024 * 1024) {
      return '${(_fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(_fileSizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  final Map<String, List<String>> _schoolModules = {
    'School of Natural Sciences and Mathematics': [
      'Calculus', 'Linear Algebra', 'Statistics & Probability',
      'Discrete Mathematics', 'Organic Chemistry', 'Analytical Chemistry',
      'Classical Physics', 'Quantum Mechanics',
    ],
    'School of Engineering Science and Technology': [
      'Software Engineering', 'Computer Science', 'ICT & Networking',
      'Electronics Engineering', 'Civil Engineering', 'Mechanical Engineering',
      'Database Systems', 'Artificial Intelligence',
    ],
    'School of Entrepreneurship and Business Sciences': [
      'Business Management', 'Accounting & Finance', 'Economics',
      'Marketing Management', 'Human Resource Management',
      'Strategic Management', 'Entrepreneurship', 'Supply Chain Management',
    ],
    'School of Agriculture Sciences and Technology': [
      'Crop Science', 'Animal Science', 'Agronomy', 'Agricultural Economics',
      'Soil Science', 'Horticulture', 'Agricultural Engineering',
      'Post-Harvest Technology',
    ],
    'School of Wildlife and Environmental Science': [
      'Wildlife Management', 'Ecology & Conservation', 'Environmental Science',
      'Tourism & Wildlife', 'Forest Management', 'Environmental Policy',
      'Animal Behaviour', 'GIS & Remote Sensing',
    ],
    'School of Health Sciences and Technology': [
      'Nursing Science', 'Public Health', 'Biomedical Science', 'Pharmacy',
      'Environmental Health', 'Medical Laboratory', 'Nutrition & Dietetics',
      'Health Informatics',
    ],
    'School of Hospitality and Tourism': [
      'Hotel Management', 'Tourism Management', 'Food & Beverage Management',
      'Events Management', 'Travel & Tourism', 'Hospitality Operations',
      'Culinary Arts', 'Resort Management',
    ],
    'School of Art and Design': [
      'Graphic Design', 'Visual Arts', 'Digital Media', 'Fine Arts',
      'Interior Design', 'Fashion Design', 'Photography', 'Animation & Film',
    ],
  };

  List<String> get _modules =>
      _selectedSchool != null ? _schoolModules[_selectedSchool!]! : [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

        // Hard block — file is too large to process on the server
        if (file.size > _hardLimitBytes) {
          _showSnack(
            'Video is too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Please use a video under 100 MB.',
          );
          return;
        }

        setState(() {
          _hasVideo = true;
          _selectedFileName = file.name;
          _filePath = file.path;
          _fileBytes = file.bytes;
          _fileSizeBytes = file.size;
        });

        // Soft warning — large files may fail on the server
        if (file.size > _warnLimitBytes) {
          _showLargeFileWarning(file.size);
        }
      }
    } catch (e) {
      setState(() {
        _hasVideo = true;
        _selectedFileName = 'selected_video.mp4';
        _filePath = null;
        _fileBytes = null;
        _fileSizeBytes = 0;
      });
    }
  }

  void _showLargeFileWarning(int sizeBytes) {
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Large File Warning',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Your video is $sizeMb MB. Large files may fail content review on the server.\n\n'
          'For best results, use a video under 50 MB.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickVideo(); // let them pick a different one
            },
            child: Text(
              'Choose another',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue anyway',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpload() async {
    if (!_hasVideo) {
      _showSnack('Please select a video first');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please add a title');
      return;
    }
    if (_selectedSchool == null) {
      _showSnack('Please select your school');
      return;
    }
    if (_selectedModule == null) {
      _showSnack('Please select a module');
      return;
    }

    // ── Step 1: Content validation ────────────────────────────────────────
    setState(() {
      _isValidating = true;
      _validatingStatus = 'Checking content...';
    });

    ValidationResult result;
    try {
      result = await ContentDetectionService.validateVideo(
        filePath: _filePath,
        fileBytes: _fileBytes,
        fileName: _selectedFileName.isNotEmpty ? _selectedFileName : 'video.mp4',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        onRetry: (attempt, total) {
          if (mounted) {
            setState(() => _validatingStatus = 'Server warming up — retrying ($attempt/$total)...');
          }
        },
      );
    } catch (e) {
      setState(() => _isValidating = false);
      debugPrint('Content validation error: $e');
      _showSnack('Content check failed: ${e.toString().split('\n').first}');
      return;
    }

    setState(() => _isValidating = false);

    if (result.status == ContentStatus.rejected) {
      _showContentRejectedDialog(result.message);
      return;
    }

    if (result.status == ContentStatus.underReview) {
      _showUnderReviewDialog(result.message);
      return;
    }

    // ── Step 2: Approved — proceed with upload ────────────────────────────
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
      'color': 0xFF131823,
      'accent': 0xFF2563EB,
      'filePath': _filePath,
      'fileBytes': _fileBytes,
    });

    setState(() => _isUploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Video uploaded successfully!',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _showContentRejectedDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Content Rejected',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : 'This video does not meet our educational content guidelines and cannot be uploaded.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnderReviewDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.orangeAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Under Review',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : 'Your video has been flagged for admin review. It will be published once approved.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back from upload screen
            },
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
            Icons.close_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        title: Text(
          'Upload Video',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          if (!_isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _handleUpload,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isValidating
          ? _buildValidatingView()
          : _isUploading
          ? _buildUploadingView()
          : FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video picker zone
                    GestureDetector(
                      onTap: _pickVideo,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        width: double.infinity,
                        height: 168,
                        decoration: BoxDecoration(
                          color: _hasVideo
                              ? AppColors.accent.withValues(alpha: 0.06)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasVideo
                                ? AppColors.accent
                                : AppColors.border,
                            width: _hasVideo ? 1.5 : 1,
                          ),
                        ),
                        child: _hasVideo
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppColors.accent,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Video selected',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFileName,
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (_fileSizeBytes > 0) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _fileSizeBytes > _warnLimitBytes
                                              ? Icons.warning_amber_rounded
                                              : Icons.storage_rounded,
                                          size: 11,
                                          color: _fileSizeBytes > _warnLimitBytes
                                              ? Colors.orangeAccent
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _fileSizeLabel,
                                          style: TextStyle(
                                            color: _fileSizeBytes > _warnLimitBytes
                                                ? Colors.orangeAccent
                                                : AppColors.textMuted,
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: _fileSizeBytes > _warnLimitBytes
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _pickVideo,
                                    child: Text(
                                      'Change video',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.video_call_rounded,
                                      color: AppColors.textTertiary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to select video',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MP4, MOV — max 60 seconds',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _FieldLabel('Video Title'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g. Introduction to Crop Rotation',
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel('Description'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descController,
                      hint: 'What will students learn from this video?',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel('School'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedSchool,
                      hint: 'Select your school',
                      icon: Icons.school_outlined,
                      items: _schoolModules.keys.toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSchool = val;
                          _selectedModule = null;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel('Module'),
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

                    // Guidelines notice
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.textTertiary,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Content Guidelines',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
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
                                    Text(
                                      '·  ',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: TextStyle(
                                          color: AppColors.textTertiary,
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
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
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Upload Video'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildValidatingView() {
    final isRetrying = _validatingStatus.contains('retrying');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRetrying ? Colors.orangeAccent : AppColors.border,
                ),
              ),
              child: Icon(
                isRetrying ? Icons.hourglass_top_rounded : Icons.shield_outlined,
                color: isRetrying ? Colors.orangeAccent : AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRetrying ? 'Please wait' : 'Checking content',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _validatingStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isRetrying ? Colors.orangeAccent : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isRetrying ? Colors.orangeAccent : AppColors.accent,
                ),
              ),
            ),
          ],
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Uploading your video',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Please keep the app open',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        color: enabled ? AppColors.surface : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppColors.surfaceVariant,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textTertiary,
        ),
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 6,
          ),
        ),
        hint: Text(
          hint,
          style: TextStyle(
            color: enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.5),
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        items: items
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ))
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}

