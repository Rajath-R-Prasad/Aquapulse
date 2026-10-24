import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int statusCode;
  final String type;
  final String title;
  final String? detail;
  final String? instance;
  final List<Map<String, dynamic>>? errors;

  const ApiException({
    required this.statusCode,
    required this.type,
    required this.title,
    this.detail,
    this.instance,
    this.errors,
  });

  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        statusCode: response.statusCode ?? 0,
        type: data['type'] as String? ?? 'unknown',
        title: data['title'] as String? ?? 'Error',
        detail: data['detail'] as String?,
        instance: data['instance'] as String?,
        errors: (data['errors'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    }
    return ApiException(
      statusCode: response.statusCode ?? 0,
      type: 'unknown',
      title: 'Unexpected error',
      detail: data?.toString(),
    );
  }

  factory ApiException.network() => const ApiException(
    statusCode: 0,
    type: 'network-error',
    title: 'Network error',
    detail:
        'Could not reach the AquaPulse API. Confirm the backend is running and API_BASE_URL is reachable from this device. Android emulator: http://10.0.2.2:8000; physical phone: use your computer LAN IP and keep the phone on the same Wi-Fi.',
  );

  String get displayMessage => detail ?? title;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode: $title - $detail)';
}
