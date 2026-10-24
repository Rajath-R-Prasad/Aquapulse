import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/work_order.dart';
import 'workorder_service.dart';

final myWorkOrdersProvider = FutureProvider.autoDispose
    .family<List<WorkOrder>, String?>((ref, status) async {
      final service = ref.watch(workOrderServiceProvider);
      return service.getMyWorkOrders(status: status);
    });

final workOrderDetailProvider = FutureProvider.autoDispose
    .family<WorkOrderDetail, String>((ref, workOrderId) async {
      final service = ref.watch(workOrderServiceProvider);
      return service.getWorkOrderDetail(workOrderId);
    });

final workOrderEvidenceProvider = FutureProvider.autoDispose
    .family<List<RepairEvidence>, String>((ref, workOrderId) async {
      final service = ref.watch(workOrderServiceProvider);
      return service.getEvidence(workOrderId);
    });

class WorkOrderNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkOrderService _service;
  final Ref _ref;

  WorkOrderNotifier(this._service, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> acceptWorkOrder(String workOrderId) async {
    state = const AsyncValue.loading();
    try {
      await _service.acceptWorkOrder(workOrderId);
      _invalidate(workOrderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> declineWorkOrder(String workOrderId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _service.declineWorkOrder(workOrderId, reason);
      _invalidate(workOrderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startTravel(String workOrderId) async {
    state = const AsyncValue.loading();
    try {
      await _service.startTravel(workOrderId);
      _invalidate(workOrderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> arrive(
    String workOrderId, {
    double? lat,
    double? lon,
    String? overrideReason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.arrive(
        workOrderId,
        lat: lat,
        lon: lon,
        overrideReason: overrideReason,
      );
      _invalidate(workOrderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitRepair(
    String workOrderId, {
    required String repairType,
    List<Material>? materials,
    int? labourMinutes,
    String? workNotes,
    List<String>? evidenceIds,
    bool allowSimulatedLocationOverride = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.submitRepair(
        workOrderId,
        repairType: repairType,
        materials: materials,
        labourMinutes: labourMinutes,
        workNotes: workNotes,
        evidenceIds: evidenceIds,
        allowSimulatedLocationOverride: allowSimulatedLocationOverride,
      );
      _invalidate(workOrderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidate(String workOrderId) {
    _ref.invalidate(myWorkOrdersProvider);
    _ref.invalidate(workOrderDetailProvider(workOrderId));
    _ref.invalidate(workOrderEvidenceProvider(workOrderId));
  }
}

final workOrderNotifierProvider =
    StateNotifierProvider<WorkOrderNotifier, AsyncValue<void>>((ref) {
      return WorkOrderNotifier(ref.watch(workOrderServiceProvider), ref);
    });
