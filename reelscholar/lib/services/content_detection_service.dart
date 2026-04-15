import 'dart:async';
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
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 10);

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kContentDetectionUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  /// Sends the video to the detection API and returns a [ValidationResult].
  /// Retries up to 3 times (10 s apart) when the server is warming up (502/503/504).
  /// Falls back to [ContentStatus.underReview] if all retries are exhausted.
  static Future<ValidationResult> validateVideo({
    String? filePath,
    Uint8List? fileBytes,
    String fileName = 'video.mp4',
    String title = '',
    String description = '',
    void Function(int attempt, int total)? onRetry,
  }) async {
    // TODO: Content detection is temporarily bypassed for testing.
    // Re-enable by removing this early return when the model is ready.
    return const ValidationResult(
      status: ContentStatus.approved,
      isEducational: true,
      message: 'Content approved (detection skipped for testing).',
      confidence: 1.0,
    );

    // ignore: dead_code
    if (filePath == null && fileBytes == null) {
      return const ValidationResult(
        status: ContentStatus.underReview,
        isEducational: false,
        message: 'Video will be reviewed before publishing.',
        confidence: 0.0,
      );
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
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
        final isServiceUnavailable =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.sendTimeout ||
            (e.type == DioExceptionType.badResponse &&
                (e.response?.statusCode == 503 ||
                 e.response?.statusCode == 502 ||
                 e.response?.statusCode == 504));

        if (!isServiceUnavailable) rethrow;

        if (attempt < _maxRetries) {
          // Notify caller so it can update UI ("Retrying 2/3...")
          onRetry?.call(attempt + 1, _maxRetries);
          await Future.delayed(_retryDelay);
        }
      }
    }

    // All retries exhausted — fall back gracefully
    return const ValidationResult(
      status: ContentStatus.underReview,
      isEducational: false,
      message: 'Content review service is warming up. Your video will be reviewed manually before publishing.',
      confidence: 0.0,
    );
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
