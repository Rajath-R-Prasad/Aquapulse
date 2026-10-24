import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/work_order.dart';
import '../../../core/network/api_client.dart';

final workOrderServiceProvider = Provider<WorkOrderService>((ref) {
  return WorkOrderService(ref.watch(dioProvider));
});

class WorkOrderService {
  final Dio _dio;

  WorkOrderService(this._dio);

  Future<List<WorkOrder>> getMyWorkOrders({
    String? status,
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _dio.get(
      '/v1/me/work-orders',
      queryParameters: {'status': ?status, 'limit': limit, 'cursor': ?cursor},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.map((item) => WorkOrder.fromJson(item)).toList();
  }

  Future<WorkOrderDetail> getWorkOrderDetail(String workOrderId) async {
    final response = await _dio.get('/v1/work-orders/$workOrderId');
    return WorkOrderDetail.fromJson(response.data);
  }

  Future<List<RepairEvidence>> getEvidence(String workOrderId) async {
    final response = await _dio.get('/v1/work-orders/$workOrderId/evidence');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    return items.map((item) => RepairEvidence.fromJson(item)).toList();
  }

  Future<void> acceptWorkOrder(
    String workOrderId, {
    String? expectedStatus,
  }) async {
    await _dio.post(
      '/v1/work-orders/$workOrderId/accept',
      data: expectedStatus != null ? {'expected_status': expectedStatus} : null,
    );
  }

  Future<void> declineWorkOrder(
    String workOrderId,
    String reason, {
    String? expectedStatus,
  }) async {
    await _dio.post(
      '/v1/work-orders/$workOrderId/decline',
      data: {'reason': reason, 'expected_status': ?expectedStatus},
    );
  }

  Future<void> startTravel(String workOrderId, {String? expectedStatus}) async {
    await _dio.post(
      '/v1/work-orders/$workOrderId/en-route',
      data: expectedStatus != null ? {'expected_status': expectedStatus} : null,
    );
  }

  Future<void> arrive(
    String workOrderId, {
    double? lat,
    double? lon,
    String? overrideReason,
    String? expectedStatus,
  }) async {
    await _dio.post(
      '/v1/work-orders/$workOrderId/arrive',
      data: {
        'lat': ?lat,
        'lon': ?lon,
        'override_reason': ?overrideReason,
        'expected_status': ?expectedStatus,
      },
    );
  }

  Future<Map<String, dynamic>> getUploadUrl(
    String workOrderId, {
    required String kind,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final response = await _dio.post(
      '/v1/work-orders/$workOrderId/evidence/upload-url',
      data: {'kind': kind, 'mime_type': mimeType, 'size_bytes': sizeBytes},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerEvidence(
    String workOrderId, {
    required String storagePath,
    required String kind,
    DateTime? capturedAt,
    double? lat,
    double? lon,
    String? sha256,
    String? mimeType,
    int? sizeBytes,
  }) async {
    final response = await _dio.post(
      '/v1/work-orders/$workOrderId/evidence',
      data: {
        'storage_path': storagePath,
        'kind': kind,
        if (capturedAt != null) 'captured_at': capturedAt.toIso8601String(),
        'lat': ?lat,
        'lon': ?lon,
        'sha256': ?sha256,
        'mime_type': ?mimeType,
        'size_bytes': ?sizeBytes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> submitRepair(
    String workOrderId, {
    required String repairType,
    List<Material>? materials,
    int? labourMinutes,
    String? workNotes,
    List<String>? evidenceIds,
    bool allowSimulatedLocationOverride = false,
    String? expectedStatus,
  }) async {
    await _dio.post(
      '/v1/work-orders/$workOrderId/submit',
      data: {
        'repair_type': repairType,
        if (materials != null)
          'materials': materials.map((m) => m.toJson()).toList(),
        'labour_minutes': ?labourMinutes,
        'work_notes': ?workNotes,
        'evidence_ids': ?evidenceIds,
        'allow_simulated_location_override': allowSimulatedLocationOverride,
        'expected_status': ?expectedStatus,
      },
    );
  }

  Future<void> updateEngineerStatus(String status) async {
    await _dio.put('/v1/me/engineer/status', data: {'status': status});
  }

  Future<void> postLocation({
    required double lat,
    required double lon,
    double? accuracyM,
    DateTime? capturedAt,
  }) async {
    await _dio.post(
      '/v1/me/location',
      data: {
        'lat': lat,
        'lon': lon,
        'accuracy_m': ?accuracyM,
        if (capturedAt != null) 'captured_at': capturedAt.toIso8601String(),
      },
    );
  }
}
