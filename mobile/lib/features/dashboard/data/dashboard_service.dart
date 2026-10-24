import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_stats.dart';
import '../../../core/models/work_order.dart';
import '../../../core/network/api_client.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(dioProvider));
});

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<List<WorkOrder>> getRecentWorkOrders({int limit = 10}) async {
    final response = await _dio.get(
      '/v1/me/work-orders',
      queryParameters: {'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.map((item) => WorkOrder.fromJson(item)).toList();
  }

  Future<DashboardStats> getStats() async {
    final response = await _dio.get(
      '/v1/me/work-orders',
      queryParameters: {'limit': 200},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((item) => WorkOrder.fromJson(item))
        .toList();

    int assignedCount = 0;
    int acceptedCount = 0;
    int enRouteCount = 0;
    int onSiteCount = 0;
    int submittedCount = 0;
    int highPriorityCount = 0;

    for (final wo in items) {
      final status = wo.status.toUpperCase();
      if (status == 'ASSIGNED') assignedCount++;
      if (status == 'ACCEPTED') acceptedCount++;
      if (status == 'EN_ROUTE') enRouteCount++;
      if (status == 'ON_SITE') onSiteCount++;
      if (status == 'SUBMITTED') submittedCount++;
      if ([
        'P1',
        'P2',
        'HIGH',
        'CRITICAL',
      ].contains(wo.priority.toUpperCase())) {
        if (!['APPROVED', 'CANCELLED', 'DECLINED'].contains(status)) {
          highPriorityCount++;
        }
      }
    }

    return DashboardStats(
      assignedCount: assignedCount,
      acceptedCount: acceptedCount,
      enRouteCount: enRouteCount,
      onSiteCount: onSiteCount,
      submittedCount: submittedCount,
      highPriorityCount: highPriorityCount,
    );
  }
}
