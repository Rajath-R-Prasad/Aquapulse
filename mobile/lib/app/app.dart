import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/services/fcm_service.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/data/notification_service.dart';
import 'router.dart';

class JalRakshakApp extends ConsumerStatefulWidget {
  const JalRakshakApp({super.key});

  @override
  ConsumerState<JalRakshakApp> createState() => _JalRakshakAppState();
}

class _JalRakshakAppState extends ConsumerState<JalRakshakApp> {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _workOrderTapSubscription;
  RealtimeChannel? _notificationChannel;
  Timer? _notificationPollTimer;
  final Set<String> _seenNotificationIds = {};
  bool _hasNotificationBaseline = false;
  String? _registeredUserId;

  @override
  void initState() {
    super.initState();
    _initializeFcm();
  }

  Future<void> _initializeFcm() async {
    final fcmService = ref.read(fcmServiceProvider);
    _workOrderTapSubscription = fcmService.workOrderTaps.listen((workOrderId) {
      if (mounted) {
        ref.read(routerProvider).go('/jobs/$workOrderId');
      }
    });
    if (!kIsWeb && !Env.enableFirebaseMessaging) {
      await fcmService.initializeLocalNotifications();
    }
    if (Env.enableFirebaseMessaging) {
      final initialized = await fcmService.initialize();
      if (initialized && mounted) await fcmService.handleInitialMessage();
    }
    if (!mounted) return;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) => _registerFcmForSession(fcmService, authState.session),
    );
    _registerFcmForSession(
      fcmService,
      Supabase.instance.client.auth.currentSession,
    );
  }

  void _registerFcmForSession(FcmService fcmService, Session? session) {
    if (session == null) {
      _registeredUserId = null;
      final channel = _notificationChannel;
      _notificationChannel = null;
      if (channel != null) {
        unawaited(Supabase.instance.client.removeChannel(channel));
      }
      _notificationPollTimer?.cancel();
      _notificationPollTimer = null;
      _seenNotificationIds.clear();
      _hasNotificationBaseline = false;
      return;
    }
    if (_registeredUserId == session.user.id) return;
    _registeredUserId = session.user.id;
    _subscribeToNotifications(fcmService, session.user.id);
    if (Env.enableFirebaseMessaging) {
      unawaited(fcmService.requestPermissionAndGetToken());
    } else {
      unawaited(fcmService.requestLocalNotificationPermission());
    }
    _seenNotificationIds.clear();
    _hasNotificationBaseline = false;
    _notificationPollTimer?.cancel();
    unawaited(_pollNotifications(fcmService));
    _notificationPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollNotifications(fcmService),
    );
  }

  void _subscribeToNotifications(FcmService fcmService, String userId) {
    final previousChannel = _notificationChannel;
    if (previousChannel != null) {
      unawaited(Supabase.instance.client.removeChannel(previousChannel));
    }

    _notificationChannel = Supabase.instance.client
        .channel('engineer-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) {
            unawaited(_handleNewNotification(payload.newRecord, fcmService));
          },
        )
        .subscribe();
  }

  Future<void> _pollNotifications(FcmService fcmService) async {
    if (!mounted || Supabase.instance.client.auth.currentSession == null) {
      return;
    }
    try {
      final response = await ref
          .read(dioProvider)
          .get('/v1/notifications', queryParameters: {'limit': 50});
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      if (!_hasNotificationBaseline) {
        _seenNotificationIds.addAll(
          items.map((item) => (item as Map<String, dynamic>)['id'] as String),
        );
        _hasNotificationBaseline = true;
        return;
      }

      for (final item in items.reversed) {
        await _handleNewNotification(item as Map<String, dynamic>, fcmService);
      }
    } catch (e, st) {
      debugPrint('Could not check for new work-order assignments: $e\n$st');
    }
  }

  Future<void> _handleNewNotification(
    Map<String, dynamic> notification,
    FcmService fcmService,
  ) async {
    final id = notification['id'] as String?;
    if (id == null || !_seenNotificationIds.add(id)) return;
    if (notification['type'] != 'WO_ASSIGNED') return;
    final payload = notification['payload'] as Map<String, dynamic>? ?? {};
    final workOrderId = payload['work_order_id'] as String?;
    if (workOrderId == null) return;

    fcmService.publishMessageEvent({
      'type': 'WO_ASSIGNED',
      'work_order_id': workOrderId,
    });
    if (!kIsWeb) {
      await fcmService.showAssignmentNotification(
        id: id,
        title: notification['title'] as String? ?? 'New work order assigned',
        body:
            notification['body'] as String? ??
            'A work order was assigned to you.',
        workOrderId: workOrderId,
      );
    }
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    final channel = _notificationChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    _authSubscription?.cancel();
    _workOrderTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'JalRakshak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
