import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_constants.dart';

enum ContentStatus { approved, rejected, underReview }

class ValidationResult {
  final ContentStatus status;
  final bool isEducational;
  final String message;
  final double confidence;

  const ValidationResult({
    required this.status,
    required this.isEducational,
    required this.message,
    required this.confidence,
  });
}

class ContentDetectionService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kContentDetectionUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Sends the video to the detection API and returns a [ValidationResult].
  /// Accepts either a file path (mobile) or raw bytes (web).
  /// If the detection service is unreachable, falls back to [ContentStatus.underReview].
  static Future<ValidationResult> validateVideo({
    String? filePath,
    Uint8List? fileBytes,
    String fileName = 'video.mp4',
    String title = '',
    String description = '',
  }) async {
    if (filePath == null && fileBytes == null) {
      // No file data — let it pass and be reviewed manually
      return const ValidationResult(
        status: ContentStatus.underReview,
        isEducational: false,
        message: 'Video will be reviewed before publishing.',
        confidence: 0.0,
      );
    }

    try {
      final formData = FormData();

      if (fileBytes != null) {
        formData.files.add(MapEntry(
          'video',
          MultipartFile.fromBytes(fileBytes, filename: fileName),
        ));
      } else {
        formData.files.add(MapEntry(
          'video',
          await MultipartFile.fromFile(filePath!, filename: fileName),
        ));
      }

      if (title.isNotEmpty) formData.fields.add(MapEntry('title', title));
      if (description.isNotEmpty) formData.fields.add(MapEntry('description', description));

      final response = await _dio.post('/api/validate-video', data: formData);
      final raw = response.data as Map<String, dynamic>? ?? {};

      return _parseResult(raw);
    } on DioException catch (e) {
      // Service is down, sleeping (Render free tier cold-start = 503),
      // or network is unavailable — fall back to underReview.
      final isServiceUnavailable =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout ||
          (e.type == DioExceptionType.badResponse &&
              (e.response?.statusCode == 503 ||
               e.response?.statusCode == 502 ||
               e.response?.statusCode == 504));

      if (isServiceUnavailable) {
        return const ValidationResult(
          status: ContentStatus.underReview,
          isEducational: false,
          message: 'Content review service is currently unavailable. Your video will be reviewed manually before publishing.',
          confidence: 0.0,
        );
      }
      // Other server error — re-throw so the caller can handle it
      rethrow;
    }
  }

  static ValidationResult _parseResult(Map<String, dynamic> raw) {
    // Support multiple possible response shapes from the API
    final isEducational =
        raw['is_educational'] as bool? ??
        raw['educational'] as bool? ??
        raw['approved'] as bool? ??
        false;

    final confidence =
        (raw['confidence'] as num?)?.toDouble() ??
        (raw['score'] as num?)?.toDouble() ??
        0.0;

    final rawStatus = (raw['status'] as String? ?? '').toLowerCase();

    ContentStatus status;
    if (rawStatus == 'under_review' || rawStatus == 'review' || rawStatus == 'pending') {
      status = ContentStatus.underReview;
    } else if (isEducational || rawStatus == 'approved') {
      status = ContentStatus.approved;
    } else {
      status = ContentStatus.rejected;
    }

    final message = raw['message'] as String? ??
        raw['detail'] as String? ??
        (status == ContentStatus.approved
            ? 'Content approved for upload.'
            : status == ContentStatus.underReview
                ? 'Content flagged for admin review.'
                : 'Content does not meet educational guidelines.');

    return ValidationResult(
      status: status,
      isEducational: isEducational,
      message: message,
      confidence: confidence,
    );
  }
}
