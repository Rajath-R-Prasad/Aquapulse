import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env.dart';
import '../../../core/models/work_order.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../workorders/data/workorder_service.dart';

final networkMapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final workOrders = ref.watch(workOrderServiceProvider);
  final response = await dio.get('/v1/network');
  final network = response.data;
  if (network is! Map<String, dynamic> || network['features'] is! List) {
    throw const FormatException(
      'The server returned invalid network map data.',
    );
  }
  final orders = await workOrders.getMyWorkOrders(limit: 200);
  return {'network': network, 'work_orders': orders};
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ref.invalidate(networkMapProvider),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(networkMapProvider);
      _startRefreshTimer();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(networkMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Map'),
        actions: [
          IconButton(
            tooltip: 'Refresh map',
            onPressed: () => ref.invalidate(networkMapProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: mapAsync.when(
        loading: () =>
            const LoadingIndicator(message: 'Loading water network…'),
        error: (error, _) => ErrorDisplay(
          message: extractApiException(error).displayMessage,
          onRetry: () => ref.invalidate(networkMapProvider),
        ),
        data: (data) {
          final features = data['network']['features'] as List<dynamic>;
          final workOrders = data['work_orders'] as List<WorkOrder>;
          final polylines = <Polyline>[];
          final markers = <Marker>[];

          for (final feature in features) {
            if (feature is! Map<String, dynamic>) continue;
            final properties = feature['properties'];
            final geometry = feature['geometry'];
            if (properties is! Map<String, dynamic> ||
                geometry is! Map<String, dynamic>) {
              continue;
            }

            if (properties['feature_type'] == 'PIPE' &&
                geometry['type'] == 'LineString') {
              final coordinates = geometry['coordinates'];
              if (coordinates is! List) continue;
              final points = coordinates
                  .whereType<List>()
                  .where((point) => point.length >= 2)
                  .map(
                    (point) => LatLng(
                      (point[1] as num).toDouble(),
                      (point[0] as num).toDouble(),
                    ),
                  )
                  .toList();
              if (points.length < 2) continue;
              final state = properties['state'] as String? ?? 'NORMAL';
              polylines.add(
                Polyline(
                  points: points,
                  color: _pipeColor(state),
                  strokeWidth: state == 'WARNING' || state == 'LEAK' ? 6 : 4,
                ),
              );
            } else if (properties['feature_type'] == 'NODE' &&
                geometry['type'] == 'Point') {
              final coordinates = geometry['coordinates'];
              if (coordinates is! List || coordinates.length < 2) continue;
              markers.add(
                Marker(
                  point: LatLng(
                    (coordinates[1] as num).toDouble(),
                    (coordinates[0] as num).toDouble(),
                  ),
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueGrey, width: 2),
                    ),
                  ),
                ),
              );
            }
          }

          for (final workOrder in workOrders) {
            if (workOrder.lat == 0 || workOrder.lon == 0) continue;
            markers.add(
              Marker(
                point: LatLng(workOrder.lat, workOrder.lon),
                width: 42,
                height: 48,
                child: Tooltip(
                  message: '${workOrder.woNo} · ${workOrder.pipeCode}',
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.severityColor(workOrder.severity),
                    size: 40,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              _MapLegend(
                pipeCount: polylines.length,
                jobCount: workOrders.length,
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(Env.mapCenterLat, Env.mapCenterLon),
                    initialZoom: Env.mapZoom.toDouble(),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.aquapulse.jalrakshak',
                    ),
                    PolylineLayer(polylines: polylines),
                    MarkerLayer(markers: markers),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _pipeColor(String state) => switch (state) {
    'WARNING' => Colors.orange,
    'LEAK' => Colors.red,
    'ISOLATED' => Colors.blueGrey,
    'UNDER_REPAIR' => Colors.purple,
    'PENDING_VERIFICATION' => Colors.teal,
    _ => Colors.blue,
  };
}

class _MapLegend extends StatelessWidget {
  final int pipeCount;
  final int jobCount;

  const _MapLegend({required this.pipeCount, required this.jobCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$pipeCount pipes',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            '$jobCount assigned jobs',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          _LegendItem(color: Colors.blue, label: 'Normal'),
          _LegendItem(color: Colors.orange, label: 'Warning'),
          _LegendItem(color: Colors.red, label: 'Leak'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
