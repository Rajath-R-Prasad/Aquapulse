// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_order.freezed.dart';
part 'work_order.g.dart';

@freezed
abstract class WorkOrder with _$WorkOrder {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkOrder({
    required String id,
    required String woNo,
    required String status,
    required String priority,
    DateTime? slaDueAt,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    String? rejectionReason,
    required DateTime createdAt,
    required String leakEventId,
    required String eventNo,
    required String severity,
    required String source,
    required bool isSimulated,
    required String pipeCode,
    required double lon,
    required double lat,
  }) = _WorkOrder;

  factory WorkOrder.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderFromJson(json);
}

@freezed
abstract class WorkOrderDetail with _$WorkOrderDetail {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkOrderDetail({
    required String id,
    required String woNo,
    required String status,
    required String priority,
    DateTime? slaDueAt,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? enRouteAt,
    DateTime? arrivedAt,
    DateTime? submittedAt,
    DateTime? approvedAt,
    String? rejectionReason,
    String? cancellationReason,
    String? approvalComment,
    required DateTime createdAt,
    required LeakEventInfo leakEvent,
    List<RepairEvidence>? evidence,
    RepairDetails? repairDetails,
  }) = _WorkOrderDetail;

  factory WorkOrderDetail.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderDetailFromJson(json);
}

@freezed
abstract class LeakEventInfo with _$LeakEventInfo {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LeakEventInfo({
    required String id,
    required String eventNo,
    required String severity,
    required String source,
    required bool isSimulated,
    required String pipeCode,
    required double lon,
    required double lat,
    double? leakConfidence,
    double? flowAnomalyScore,
    double? pressureDropPa,
    double? estimatedLeakRateLpm,
    double? estimatedLossPct,
    double? chainageM,
    DateTime? detectedAt,
  }) = _LeakEventInfo;

  factory LeakEventInfo.fromJson(Map<String, dynamic> json) =>
      _$LeakEventInfoFromJson(json);
}

@freezed
abstract class RepairEvidence with _$RepairEvidence {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RepairEvidence({
    required String id,
    required String kind,
    required String storagePath,
    required String mimeType,
    int? sizeBytes,
    DateTime? capturedAt,
    double? distanceToLeakM,
    bool? geoValid,
    required DateTime createdAt,
    double? lon,
    double? lat,
    String? url,
  }) = _RepairEvidence;

  factory RepairEvidence.fromJson(Map<String, dynamic> json) =>
      _$RepairEvidenceFromJson(json);
}

@freezed
abstract class RepairDetails with _$RepairDetails {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RepairDetails({
    required String repairType,
    List<Material>? materials,
    int? labourMinutes,
    String? workNotes,
  }) = _RepairDetails;

  factory RepairDetails.fromJson(Map<String, dynamic> json) =>
      _$RepairDetailsFromJson(json);
}

@freezed
abstract class Material with _$Material {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Material({required String item, required double qty}) =
      _Material;

  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);
}

enum WorkOrderStatus {
  assigned,
  accepted,
  declined,
  enRoute,
  onSite,
  submitted,
  approved,
  rework,
  cancelled;

  String get displayName {
    switch (this) {
      case WorkOrderStatus.assigned:
        return 'Assigned';
      case WorkOrderStatus.accepted:
        return 'Accepted';
      case WorkOrderStatus.declined:
        return 'Declined';
      case WorkOrderStatus.enRoute:
        return 'En Route';
      case WorkOrderStatus.onSite:
        return 'On Site';
      case WorkOrderStatus.submitted:
        return 'Submitted';
      case WorkOrderStatus.approved:
        return 'Approved';
      case WorkOrderStatus.rework:
        return 'Rework';
      case WorkOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static WorkOrderStatus? fromString(String status) {
    final normalized = status.toUpperCase();
    switch (normalized) {
      case 'ASSIGNED':
        return WorkOrderStatus.assigned;
      case 'ACCEPTED':
        return WorkOrderStatus.accepted;
      case 'DECLINED':
        return WorkOrderStatus.declined;
      case 'EN_ROUTE':
        return WorkOrderStatus.enRoute;
      case 'ON_SITE':
        return WorkOrderStatus.onSite;
      case 'SUBMITTED':
        return WorkOrderStatus.submitted;
      case 'APPROVED':
        return WorkOrderStatus.approved;
      case 'REWORK':
        return WorkOrderStatus.rework;
      case 'CANCELLED':
        return WorkOrderStatus.cancelled;
      default:
        return null;
    }
  }
}
