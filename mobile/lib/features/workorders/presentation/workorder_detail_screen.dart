import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/env.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/work_order.dart';
import '../../../core/network/api_client.dart';
import '../../workorders/data/workorder_provider.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workOrderDetailProvider(workOrderId));
    final evidenceAsync = ref.watch(workOrderEvidenceProvider(workOrderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(workOrderDetailProvider(workOrderId));
              ref.invalidate(workOrderEvidenceProvider(workOrderId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workOrderDetailProvider(workOrderId));
            ref.invalidate(workOrderEvidenceProvider(workOrderId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(detail: detail),
                const SizedBox(height: 16),
                _NextStepCard(status: detail.status),
                const SizedBox(height: 16),
                _LocationCard(
                  lat: detail.leakEvent.lat,
                  lon: detail.leakEvent.lon,
                  pipeCode: detail.leakEvent.pipeCode,
                ),
                const SizedBox(height: 16),
                _LeakEventCard(event: detail.leakEvent),
                const SizedBox(height: 16),
                _TimelineCard(detail: detail),
                const SizedBox(height: 16),
                evidenceAsync.when(
                  data: (evidence) => _EvidenceSection(evidence: evidence),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, st) => ErrorDisplay(
                    message: 'Could not load repair photos',
                    onRetry: () =>
                        ref.invalidate(workOrderEvidenceProvider(workOrderId)),
                  ),
                ),
                const SizedBox(height: 16),
                _ActionButtons(detail: detail, workOrderId: workOrderId),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        loading: () => const LoadingIndicator(message: 'Loading details...'),
        error: (e, st) {
          final apiError = extractApiException(e);
          final message = apiError.statusCode != 0
              ? 'Could not load work order details '
                    '(${apiError.statusCode}): ${apiError.displayMessage}'
              : 'Could not load work order details: $e';
          return ErrorDisplay(
            message: message,
            onRetry: () => ref.invalidate(workOrderDetailProvider(workOrderId)),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final WorkOrderDetail detail;

  const _HeaderCard({required this.detail});

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MEDIUM':
        return Colors.blue.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return Colors.blue;
      case 'ACCEPTED':
        return Colors.green;
      case 'EN_ROUTE':
        return Colors.orange;
      case 'ON_SITE':
        return Colors.purple;
      case 'SUBMITTED':
        return Colors.teal;
      case 'APPROVED':
        return Colors.green.shade700;
      case 'REWORK':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail.woNo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      detail.priority,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getPriorityColor(detail.priority),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    detail.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(detail.priority),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(detail.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                detail.status.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(detail.status),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event,
              label: 'Work order created',
              value: DateFormat('MMM d, yyyy h:mm a').format(detail.createdAt),
            ),
            if (detail.slaDueAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SLA Due',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy h:mm a',
                            ).format(detail.slaDueAt!),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  final String status;

  const _NextStepCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (title, message, icon) = switch (status.toUpperCase()) {
      'ASSIGNED' => (
        'Step 1 · Accept the assignment',
        'Review the incident details, then accept the job to begin.',
        Icons.assignment_turned_in,
      ),
      'ACCEPTED' => (
        'Step 2 · Travel to the site',
        'Tap Start Travel when you are on your way.',
        Icons.directions_car,
      ),
      'EN_ROUTE' => (
        'Step 3 · Arrive at the leak',
        'Use Arrive on Site when you reach the location shown on the map.',
        Icons.location_on,
      ),
      'ON_SITE' || 'REWORK' => (
        'Step 4 · Record and submit the repair',
        'Take a before photo, complete the repair, then take an after photo. '
            'Add repair notes and submit for operator review.',
        Icons.build,
      ),
      'SUBMITTED' => (
        'Waiting for operator acknowledgment',
        'Your repair and photos have been submitted. The work order closes '
            'only after the operator reviews and approves it. If rejected, '
            'the job returns to you for rework.',
        Icons.hourglass_top,
      ),
      'COMPLETED' => (
        'Repair approved and work order closed',
        'The operator acknowledged the repair submission.',
        Icons.verified,
      ),
      'CANCELLED' => (
        'Work order cancelled',
        'This work order is no longer active.',
        Icons.cancel_outlined,
      ),
      _ => (
        'Work order status: ${status.replaceAll('_', ' ')}',
        'Follow the latest instructions from the operator.',
        Icons.info_outline,
      ),
    };

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message),
        ),
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final double lat;
  final double lon;
  final String pipeCode;

  const _LocationCard({
    required this.lat,
    required this.lon,
    required this.pipeCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident Location',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pipe: $pipeCode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lon),
                initialZoom: Env.mapZoom.toDouble(),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aquapulse.jalrakshak',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lon),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.water_damage,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    if (locationAsync.hasValue && locationAsync.value != null)
                      Marker(
                        point: LatLng(
                          locationAsync.value!.latitude,
                          locationAsync.value!.longitude,
                        ),
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person_pin,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                locationAsync.when(
                  data: (position) {
                    if (position == null) {
                      return Text(
                        'Location unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      );
                    }
                    final distance = Geolocator.distanceBetween(
                      position.latitude,
                      position.longitude,
                      lat,
                      lon,
                    );
                    return Text(
                      '${(distance / 1000).toStringAsFixed(2)} km away',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeakEventCard extends StatelessWidget {
  final LeakEventInfo event;

  const _LeakEventCard({required this.event});

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.yellow.shade700;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leak Event Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event_note,
              label: 'Event No',
              value: event.eventNo,
            ),
            if (event.detectedAt != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Detected',
                value: DateFormat(
                  'MMM d, yyyy h:mm a',
                ).format(event.detectedAt!),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Severity:',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(event.severity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  event.severity,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getSeverityColor(event.severity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.source,
              label: 'Source',
              value:
                  '${event.source}${event.isSimulated ? ' (Simulated)' : ''}',
            ),
            if (event.leakConfidence != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.analytics,
                label: 'Leak Confidence',
                value: '${(event.leakConfidence! * 100).toStringAsFixed(1)}%',
              ),
            ],
            if (event.estimatedLeakRateLpm != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.water_drop,
                label: 'Estimated leak rate',
                value:
                    '${event.estimatedLeakRateLpm!.toStringAsFixed(1)} L/min',
              ),
            ],
            if (event.estimatedLossPct != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.percent,
                label: 'Estimated water loss',
                value: '${event.estimatedLossPct!.toStringAsFixed(1)}%',
              ),
            ],
            if (event.chainageM != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.straighten,
                label: 'Along pipe',
                value: '${event.chainageM!.toStringAsFixed(1)} m',
              ),
            ],
            if (event.flowAnomalyScore != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.trending_up,
                label: 'Flow Anomaly',
                value: event.flowAnomalyScore!.toStringAsFixed(2),
              ),
            ],
            if (event.pressureDropPa != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.compress,
                label: 'Pressure Drop',
                value: '${event.pressureDropPa!.toStringAsFixed(1)} Pa',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final WorkOrderDetail detail;

  const _TimelineCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final events = <Map<String, dynamic>>[];

    if (detail.assignedAt != null) {
      events.add({
        'title': 'Assigned',
        'time': detail.assignedAt,
        'icon': Icons.assignment,
      });
    }
    if (detail.acceptedAt != null) {
      events.add({
        'title': 'Accepted',
        'time': detail.acceptedAt,
        'icon': Icons.check_circle,
      });
    }
    if (detail.enRouteAt != null) {
      events.add({
        'title': 'En Route',
        'time': detail.enRouteAt,
        'icon': Icons.directions_car,
      });
    }
    if (detail.arrivedAt != null) {
      events.add({
        'title': 'Arrived',
        'time': detail.arrivedAt,
        'icon': Icons.location_on,
      });
    }
    if (detail.submittedAt != null) {
      events.add({
        'title': 'Submitted',
        'time': detail.submittedAt,
        'icon': Icons.done_all,
      });
    }
    if (detail.approvedAt != null) {
      events.add({
        'title': 'Approved',
        'time': detail.approvedAt,
        'icon': Icons.verified,
      });
    }

    if (events.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      e['icon'] as IconData,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, h:mm a').format(e['time'] as DateTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  final List<dynamic> evidence;

  const _EvidenceSection({required this.evidence});

  @override
  Widget build(BuildContext context) {
    if (evidence.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence (${evidence.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: evidence.map((e) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: e.url != null
                        ? Image.network(e.url, fit: BoxFit.cover)
                        : Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final WorkOrderDetail detail;
  final String workOrderId;

  const _ActionButtons({required this.detail, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = detail.status.toUpperCase();
    final actionState = ref.watch(workOrderNotifierProvider);

    return Column(
      children: [
        if (actionState.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _actionError(actionState.error!),
          ),
        if (status == 'ASSIGNED') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => _handleAccept(context, ref),
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Job'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => _handleDecline(context, ref),
              icon: const Icon(Icons.cancel),
              label: const Text('Decline Job'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        if (status == 'ACCEPTED') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => _handleEnRoute(context, ref),
              icon: const Icon(Icons.directions_car),
              label: const Text('Start Travel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        if (status == 'EN_ROUTE') ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Arrive on Site is verified against the incident GPS location. '
              'If you are at the site but GPS is inaccurate or unavailable, '
              'use the separate override and provide a reason.',
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => _handleArrive(context, ref),
              icon: const Icon(Icons.location_on),
              label: const Text('Arrive on Site'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => _handleArrivalOverride(context, ref),
              icon: const Icon(Icons.gps_off),
              label: const Text('Bypass arrival GPS check'),
            ),
          ),
        ],
        if (status == 'ON_SITE' || status == 'REWORK') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionState.isLoading
                  ? null
                  : () => context.push('/jobs/$workOrderId/submit-repair'),
              icon: const Icon(Icons.build),
              label: const Text('Submit Repair'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionError(Object error) {
    final apiError = extractApiException(error);
    final message = apiError.statusCode == 0
        ? 'Work-order action failed: $error'
        : 'Work-order action failed (${apiError.statusCode}): '
              '${apiError.displayMessage}';
    return ErrorDisplay(message: message);
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(workOrderNotifierProvider.notifier);
    await notifier.acceptWorkOrder(workOrderId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(workOrderNotifierProvider).hasError
                ? 'Could not accept job'
                : 'Job accepted',
          ),
        ),
      );
    }
  }

  Future<void> _handleDecline(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _DeclineDialog(),
    );
    if (reason == null || reason.isEmpty) return;

    final notifier = ref.read(workOrderNotifierProvider.notifier);
    await notifier.declineWorkOrder(workOrderId, reason);
    if (context.mounted) {
      if (ref.read(workOrderNotifierProvider).hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not decline job')));
      } else {
        context.pop();
      }
    }
  }

  Future<void> _handleEnRoute(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(workOrderNotifierProvider.notifier);
    await notifier.startTravel(workOrderId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(workOrderNotifierProvider).hasError
                ? 'Could not start travel'
                : 'Travel started',
          ),
        ),
      );
    }
  }

  Future<void> _handleArrive(BuildContext context, WidgetRef ref) async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();

    if (position == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not verify your location. Enable GPS or use the separate '
              'arrival override button.',
            ),
          ),
        );
      }
      return;
    }

    final notifier = ref.read(workOrderNotifierProvider.notifier);
    await notifier.arrive(
      workOrderId,
      lat: position.latitude,
      lon: position.longitude,
    );

    if (context.mounted) {
      final result = ref.read(workOrderNotifierProvider);
      if (result.hasError) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as arrived')));
    }
  }

  Future<void> _handleArrivalOverride(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ArrivalOverrideDialog(),
    );
    if (reason == null || !context.mounted) return;

    final position = await ref
        .read(locationServiceProvider)
        .getCurrentPosition();
    final notifier = ref.read(workOrderNotifierProvider.notifier);
    await notifier.arrive(
      workOrderId,
      lat: position?.latitude,
      lon: position?.longitude,
      overrideReason: reason,
    );

    if (!context.mounted) return;
    final result = ref.read(workOrderNotifierProvider);
    if (result.hasError) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arrival marked. The GPS override was recorded.'),
      ),
    );
  }
}

class _ArrivalOverrideDialog extends StatefulWidget {
  @override
  State<_ArrivalOverrideDialog> createState() => _ArrivalOverrideDialogState();
}

class _ArrivalOverrideDialogState extends State<_ArrivalOverrideDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bypass arrival GPS check?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Use this only if you are physically at the work site and GPS is '
            'inaccurate or unavailable. The operator will see that the '
            'geofence was bypassed and your reason.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for override',
              hintText: 'e.g. GPS signal inaccurate at the work site',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Confirm arrival'),
        ),
      ],
    );
  }
}

class _DeclineDialog extends StatefulWidget {
  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline Job'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Reason for declining',
          hintText: 'Enter reason...',
        ),
        maxLines: 3,
        maxLength: 500,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}
