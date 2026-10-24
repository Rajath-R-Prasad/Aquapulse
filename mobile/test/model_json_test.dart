import 'package:flutter_test/flutter_test.dart';
import 'package:jalrakshak/core/models/user_profile.dart';
import 'package:jalrakshak/core/models/work_order.dart';

void main() {
  test('parses snake-case engineer profile response', () {
    final profile = UserProfile.fromJson({
      'id': 'profile-1',
      'full_name': 'Ravi Kumar',
      'role': 'ENGINEER',
      'phone': null,
      'engineer': {
        'employee_code': 'ENG-001',
        'status': 'AVAILABLE',
        'skills': ['PIPE_REPAIR', 'VALVE'],
        'max_active_jobs': 1,
      },
    });

    expect(profile.fullName, 'Ravi Kumar');
    expect(profile.engineer?.employeeCode, 'ENG-001');
    expect(profile.engineer?.maxActiveJobs, 1);
  });

  test('parses snake-case assigned-work response', () {
    final workOrder = WorkOrder.fromJson({
      'id': 'work-order-1',
      'wo_no': 'WO-2026-000001',
      'status': 'ASSIGNED',
      'priority': 'P2',
      'created_at': '2026-10-22T10:00:00Z',
      'leak_event_id': 'event-1',
      'event_no': 'LK-2026-000001',
      'severity': 'MAJOR',
      'source': 'TWIN',
      'is_simulated': true,
      'pipe_code': 'P05',
      'lon': 76.6394,
      'lat': 12.2958,
    });

    expect(workOrder.woNo, 'WO-2026-000001');
    expect(workOrder.leakEventId, 'event-1');
    expect(workOrder.pipeCode, 'P05');
    expect(workOrder.isSimulated, isTrue);
  });

  test('parses nested snake-case work-order detail response', () {
    final detail = WorkOrderDetail.fromJson({
      'id': 'work-order-1',
      'wo_no': 'WO-2026-000001',
      'status': 'ASSIGNED',
      'priority': 'P2',
      'created_at': '2026-10-22T10:00:00Z',
      'leak_event': {
        'id': 'event-1',
        'event_no': 'LK-2026-000001',
        'severity': 'MAJOR',
        'source': 'TWIN',
        'is_simulated': true,
        'pipe_code': 'P05',
        'lon': 76.6394,
        'lat': 12.2958,
        'estimated_leak_rate_lpm': 18.5,
        'estimated_loss_pct': 6.2,
        'chainage_m': 125.0,
        'detected_at': '2026-10-22T09:45:00Z',
      },
      'repair_details': null,
    });

    expect(detail.leakEvent.eventNo, 'LK-2026-000001');
    expect(detail.leakEvent.pipeCode, 'P05');
    expect(detail.leakEvent.isSimulated, isTrue);
    expect(detail.leakEvent.estimatedLeakRateLpm, 18.5);
    expect(detail.leakEvent.estimatedLossPct, 6.2);
    expect(detail.leakEvent.chainageM, 125.0);
  });

  test('parses evidence when optional capture metadata is absent', () {
    final evidence = RepairEvidence.fromJson({
      'id': 'evidence-1',
      'kind': 'BEFORE_PHOTO',
      'storage_path': 'repair-evidence/work-order/photo.jpg',
      'mime_type': 'image/jpeg',
      'size_bytes': null,
      'captured_at': null,
      'distance_to_leak_m': null,
      'geo_valid': null,
      'created_at': '2026-10-22T10:00:00Z',
      'lon': null,
      'lat': null,
      'url': null,
    });

    expect(evidence.id, 'evidence-1');
    expect(evidence.capturedAt, isNull);
    expect(evidence.sizeBytes, isNull);
    expect(evidence.geoValid, isNull);
  });
}
