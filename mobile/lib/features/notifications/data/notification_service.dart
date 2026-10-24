import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification.dart';
import '../../../core/network/api_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(dioProvider));
});

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _dio.get(
      '/v1/notifications',
      queryParameters: {
        'unread_only': unreadOnly,
        'limit': limit,
        'cursor': ?cursor,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.map((item) => AppNotification.fromJson(item)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.post('/v1/notifications/$notificationId/read');
  }

  Future<void> registerPushToken(String token, String platform) async {
    await _dio.post('/v1/me/push-token', data: {
      'token': token,
      'platform': platform,
    });
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications();
});

final unreadNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications(unreadOnly: true);
});
