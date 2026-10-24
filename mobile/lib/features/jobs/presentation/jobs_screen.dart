import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

final workOrdersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, status) async {
      final dio = ref.watch(dioProvider);
      final queryParams = <String, dynamic>{'limit': 50};
      if (status != null) queryParams['status'] = status;
      final response = await dio.get(
        '/v1/me/work-orders',
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    });

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, String>>? _messageSubscription;

  static const _tabs = [
    (label: 'Active', status: null),
    (label: 'Assigned', status: 'ASSIGNED'),
    (label: 'Submitted', status: 'SUBMITTED'),
    (label: 'Completed', status: 'COMPLETED'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    if (Env.enableFirebaseMessaging) {
      _messageSubscription = ref
          .read(fcmServiceProvider)
          .messageEvents
          .listen(_onPushMessage);
    }
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshVisibleTab(),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _refreshVisibleTab();
  }

  void _onPushMessage(Map<String, String> data) {
    if (data['type'] == 'WO_ASSIGNED' || data.containsKey('work_order_id')) {
      _refreshAll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshVisibleTab();
  }

  void _refreshVisibleTab() {
    if (!mounted) return;
    ref.invalidate(workOrdersProvider(_tabs[_tabController.index].status));
  }

  void _refreshAll() {
    for (final tab in _tabs) {
      ref.invalidate(workOrdersProvider(tab.status));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _JobList(statusFilter: t.status)).toList(),
      ),
    );
  }
}

class _JobList extends ConsumerWidget {
  final String? statusFilter;

  const _JobList({required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(workOrdersProvider(statusFilter));

    return ordersAsync.when(
      data: (data) {
        final items = data['items'] as List? ?? [];
        return RefreshIndicator(
          onRefresh: () => ref
              .refresh(workOrdersProvider(statusFilter).future)
              .then<void>((_) {}),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.isEmpty ? 1 : items.length,
            itemBuilder: (context, i) {
              if (items.isEmpty) {
                return const SizedBox(
                  height: 240,
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No work orders',
                    subtitle: 'Pull down to check for newly assigned jobs.',
                  ),
                );
              }
              final wo = items[i] as Map<String, dynamic>;
              return _WorkOrderCard(wo: wo);
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading jobs...'),
      error: (e, _) {
        final apiErr = extractApiException(e);
        return ErrorDisplay(
          message: apiErr.displayMessage,
          onRetry: () => ref.invalidate(workOrdersProvider(statusFilter)),
        );
      },
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final Map<String, dynamic> wo;

  const _WorkOrderCard({required this.wo});

  @override
  Widget build(BuildContext context) {
    final woNo = wo['wo_no'] as String? ?? '';
    final status = wo['status'] as String? ?? '';
    final severity = wo['severity'] as String? ?? '';
    final priority = wo['priority'] as String? ?? '';
    final pipeCode = wo['pipe_code'] as String? ?? '';
    final eventNo = wo['event_no'] as String? ?? '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/jobs/${wo['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      woNo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StatusBadge(
                    label: status,
                    color: AppTheme.woStatusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SeverityIndicator(
                    severity: severity,
                    color: AppTheme.severityColor(severity),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.flag, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    priority,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.water, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Pipe $pipeCode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.tag, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    eventNo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View job details  →',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
