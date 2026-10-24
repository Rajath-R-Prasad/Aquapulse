import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dio/dio.dart';

import '../network/api_client.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(dioProvider));
});

class FcmService {
  final Dio _dio;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, String>> _messageEvents =
      StreamController<Map<String, String>>.broadcast();
  final StreamController<String> _workOrderTaps =
      StreamController<String>.broadcast();

  bool _localNotificationsInitialized = false;
  bool _firebaseMessagingInitialized = false;

  FcmService(this._dio);

  Stream<Map<String, String>> get messageEvents => _messageEvents.stream;
  Stream<String> get workOrderTaps => _workOrderTaps.stream;

  Future<bool> initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return true;
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      if (!kIsWeb && Platform.isAndroid) {
        final android = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'Work-order assignment notifications.',
            importance: Importance.high,
          ),
        );
      }

      _localNotificationsInitialized = true;
      return true;
    } catch (e, st) {
      debugPrint('Local notification initialization failed: $e\n$st');
      return false;
    }
  }

  Future<bool> initialize() async {
    if (_firebaseMessagingInitialized) return true;
    if (!await initializeLocalNotifications()) return false;
    try {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen(
        _registerTokenWithBackend,
      );

      _firebaseMessagingInitialized = true;
      return true;
    } catch (e, st) {
      debugPrint('FCM initialization failed: $e\n$st');
      return false;
    }
  }

  Future<void> requestLocalNotificationPermission() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e, st) {
      debugPrint('Could not request notification permission: $e\n$st');
    }
  }

  Future<void> handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleOpenedMessage(message);
  }

  Future<String?> requestPermissionAndGetToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          await _registerTokenWithBackend(token);
        }
        return token;
      }
      return null;
    } catch (e, st) {
      debugPrint('Could not obtain an FCM token: $e\n$st');
      return null;
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      final platform = Platform.isAndroid ? 'ANDROID' : 'IOS';
      await _dio.post(
        '/v1/me/push-token',
        data: {'token': token, 'platform': platform},
      );
    } catch (e, st) {
      debugPrint('Could not register the FCM token with the backend: $e\n$st');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _messageEvents.add(_stringData(message.data));
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['work_order_id'] as String?,
      );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    publishMessageEvent(_stringData(message.data));
    final workOrderId = message.data['work_order_id'];
    if (workOrderId != null) _workOrderTaps.add(workOrderId);
  }

  void publishMessageEvent(Map<String, String> data) {
    _messageEvents.add(data);
  }

  Future<void> showAssignmentNotification({
    required String id,
    required String title,
    required String body,
    required String workOrderId,
  }) async {
    if (!_localNotificationsInitialized || kIsWeb) return;
    await _localNotifications.show(
      id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Work-order assignment notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: workOrderId,
    );
  }

  Map<String, String> _stringData(Map<String, dynamic> data) =>
      data.map((key, value) => MapEntry(key, value.toString()));

  void _handleNotificationTap(NotificationResponse response) {
    final workOrderId = response.payload;
    if (workOrderId != null && workOrderId.isNotEmpty) {
      _workOrderTaps.add(workOrderId);
    }
  }
}
