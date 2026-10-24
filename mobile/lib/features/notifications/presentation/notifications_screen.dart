import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/common_widgets.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                subtitle: 'You will receive notifications here',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            );
          },
          loading: () =>
              const LoadingIndicator(message: 'Loading notifications...'),
          error: (e, st) => ErrorDisplay(
            message: 'Failed to load notifications',
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final dynamic notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = notification.readAt == null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUnread
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        child: Icon(
          _getIconForType(notification.type),
          color: isUnread
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null && notification.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notification.body!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(notification.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      isThreeLine: notification.body != null && notification.body!.isNotEmpty,
      onTap: () async {
        if (isUnread) {
          final service = ref.read(notificationServiceProvider);
          await service.markAsRead(notification.id);
          ref.invalidate(notificationsProvider);
        }

        if (notification.payload != null) {
          final workOrderId = notification.payload?['work_order_id'] as String?;
          if (workOrderId != null && context.mounted) {
            context.push('/jobs/$workOrderId');
          }
        }
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'WO_ASSIGNED':
      case 'WORK_ORDER_ASSIGNED':
        return Icons.assignment;
      case 'WORK_ORDER_UPDATED':
        return Icons.update;
      case 'WORK_ORDER_CANCELLED':
        return Icons.cancel;
      case 'PRIORITY_ALERT':
        return Icons.priority_high;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
