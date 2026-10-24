import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_stats.dart';
import '../../../core/models/work_order.dart';
import 'dashboard_service.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getStats();
});

final recentWorkOrdersProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getRecentWorkOrders(limit: 10);
});

final highPriorityWorkOrdersProvider = FutureProvider<List<WorkOrder>>((
  ref,
) async {
  final allOrders = await ref.watch(recentWorkOrdersProvider.future);
  return allOrders
      .where(
        (wo) =>
            [
              'P1',
              'P2',
              'HIGH',
              'CRITICAL',
            ].contains(wo.priority.toUpperCase()) &&
            ![
              'APPROVED',
              'CANCELLED',
              'DECLINED',
            ].contains(wo.status.toUpperCase()),
      )
      .toList();
});
