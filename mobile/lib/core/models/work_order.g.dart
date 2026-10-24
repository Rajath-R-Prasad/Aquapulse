// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkOrder _$WorkOrderFromJson(Map<String, dynamic> json) => _WorkOrder(
  id: json['id'] as String,
  woNo: json['wo_no'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String,
  slaDueAt: json['sla_due_at'] == null
      ? null
      : DateTime.parse(json['sla_due_at'] as String),
  assignedAt: json['assigned_at'] == null
      ? null
      : DateTime.parse(json['assigned_at'] as String),
  acceptedAt: json['accepted_at'] == null
      ? null
      : DateTime.parse(json['accepted_at'] as String),
  arrivedAt: json['arrived_at'] == null
      ? null
      : DateTime.parse(json['arrived_at'] as String),
  rejectionReason: json['rejection_reason'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  leakEventId: json['leak_event_id'] as String,
  eventNo: json['event_no'] as String,
  severity: json['severity'] as String,
  source: json['source'] as String,
  isSimulated: json['is_simulated'] as bool,
  pipeCode: json['pipe_code'] as String,
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
);

Map<String, dynamic> _$WorkOrderToJson(_WorkOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wo_no': instance.woNo,
      'status': instance.status,
      'priority': instance.priority,
      'sla_due_at': instance.slaDueAt?.toIso8601String(),
      'assigned_at': instance.assignedAt?.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'arrived_at': instance.arrivedAt?.toIso8601String(),
      'rejection_reason': instance.rejectionReason,
      'created_at': instance.createdAt.toIso8601String(),
      'leak_event_id': instance.leakEventId,
      'event_no': instance.eventNo,
      'severity': instance.severity,
      'source': instance.source,
      'is_simulated': instance.isSimulated,
      'pipe_code': instance.pipeCode,
      'lon': instance.lon,
      'lat': instance.lat,
    };

_WorkOrderDetail _$WorkOrderDetailFromJson(
  Map<String, dynamic> json,
) => _WorkOrderDetail(
  id: json['id'] as String,
  woNo: json['wo_no'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String,
  slaDueAt: json['sla_due_at'] == null
      ? null
      : DateTime.parse(json['sla_due_at'] as String),
  assignedAt: json['assigned_at'] == null
      ? null
      : DateTime.parse(json['assigned_at'] as String),
  acceptedAt: json['accepted_at'] == null
      ? null
      : DateTime.parse(json['accepted_at'] as String),
  enRouteAt: json['en_route_at'] == null
      ? null
      : DateTime.parse(json['en_route_at'] as String),
  arrivedAt: json['arrived_at'] == null
      ? null
      : DateTime.parse(json['arrived_at'] as String),
  submittedAt: json['submitted_at'] == null
      ? null
      : DateTime.parse(json['submitted_at'] as String),
  approvedAt: json['approved_at'] == null
      ? null
      : DateTime.parse(json['approved_at'] as String),
  rejectionReason: json['rejection_reason'] as String?,
  cancellationReason: json['cancellation_reason'] as String?,
  approvalComment: json['approval_comment'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  leakEvent: LeakEventInfo.fromJson(json['leak_event'] as Map<String, dynamic>),
  evidence: (json['evidence'] as List<dynamic>?)
      ?.map((e) => RepairEvidence.fromJson(e as Map<String, dynamic>))
      .toList(),
  repairDetails: json['repair_details'] == null
      ? null
      : RepairDetails.fromJson(json['repair_details'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WorkOrderDetailToJson(_WorkOrderDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wo_no': instance.woNo,
      'status': instance.status,
      'priority': instance.priority,
      'sla_due_at': instance.slaDueAt?.toIso8601String(),
      'assigned_at': instance.assignedAt?.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'en_route_at': instance.enRouteAt?.toIso8601String(),
      'arrived_at': instance.arrivedAt?.toIso8601String(),
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'approved_at': instance.approvedAt?.toIso8601String(),
      'rejection_reason': instance.rejectionReason,
      'cancellation_reason': instance.cancellationReason,
      'approval_comment': instance.approvalComment,
      'created_at': instance.createdAt.toIso8601String(),
      'leak_event': instance.leakEvent,
      'evidence': instance.evidence,
      'repair_details': instance.repairDetails,
    };

_LeakEventInfo _$LeakEventInfoFromJson(Map<String, dynamic> json) =>
    _LeakEventInfo(
      id: json['id'] as String,
      eventNo: json['event_no'] as String,
      severity: json['severity'] as String,
      source: json['source'] as String,
      isSimulated: json['is_simulated'] as bool,
      pipeCode: json['pipe_code'] as String,
      lon: (json['lon'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      leakConfidence: (json['leak_confidence'] as num?)?.toDouble(),
      flowAnomalyScore: (json['flow_anomaly_score'] as num?)?.toDouble(),
      pressureDropPa: (json['pressure_drop_pa'] as num?)?.toDouble(),
      estimatedLeakRateLpm: (json['estimated_leak_rate_lpm'] as num?)
          ?.toDouble(),
      estimatedLossPct: (json['estimated_loss_pct'] as num?)?.toDouble(),
      chainageM: (json['chainage_m'] as num?)?.toDouble(),
      detectedAt: json['detected_at'] == null
          ? null
          : DateTime.parse(json['detected_at'] as String),
    );

Map<String, dynamic> _$LeakEventInfoToJson(_LeakEventInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_no': instance.eventNo,
      'severity': instance.severity,
      'source': instance.source,
      'is_simulated': instance.isSimulated,
      'pipe_code': instance.pipeCode,
      'lon': instance.lon,
      'lat': instance.lat,
      'leak_confidence': instance.leakConfidence,
      'flow_anomaly_score': instance.flowAnomalyScore,
      'pressure_drop_pa': instance.pressureDropPa,
      'estimated_leak_rate_lpm': instance.estimatedLeakRateLpm,
      'estimated_loss_pct': instance.estimatedLossPct,
      'chainage_m': instance.chainageM,
      'detected_at': instance.detectedAt?.toIso8601String(),
    };

_RepairEvidence _$RepairEvidenceFromJson(Map<String, dynamic> json) =>
    _RepairEvidence(
      id: json['id'] as String,
      kind: json['kind'] as String,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      capturedAt: json['captured_at'] == null
          ? null
          : DateTime.parse(json['captured_at'] as String),
      distanceToLeakM: (json['distance_to_leak_m'] as num?)?.toDouble(),
      geoValid: json['geo_valid'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lon: (json['lon'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      url: json['url'] as String?,
    );

Map<String, dynamic> _$RepairEvidenceToJson(_RepairEvidence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'storage_path': instance.storagePath,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'captured_at': instance.capturedAt?.toIso8601String(),
      'distance_to_leak_m': instance.distanceToLeakM,
      'geo_valid': instance.geoValid,
      'created_at': instance.createdAt.toIso8601String(),
      'lon': instance.lon,
      'lat': instance.lat,
      'url': instance.url,
    };

_RepairDetails _$RepairDetailsFromJson(Map<String, dynamic> json) =>
    _RepairDetails(
      repairType: json['repair_type'] as String,
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => Material.fromJson(e as Map<String, dynamic>))
          .toList(),
      labourMinutes: (json['labour_minutes'] as num?)?.toInt(),
      workNotes: json['work_notes'] as String?,
    );

Map<String, dynamic> _$RepairDetailsToJson(_RepairDetails instance) =>
    <String, dynamic>{
      'repair_type': instance.repairType,
      'materials': instance.materials,
      'labour_minutes': instance.labourMinutes,
      'work_notes': instance.workNotes,
    };

_Material _$MaterialFromJson(Map<String, dynamic> json) => _Material(
  item: json['item'] as String,
  qty: (json['qty'] as num).toDouble(),
);

Map<String, dynamic> _$MaterialToJson(_Material instance) => <String, dynamic>{
  'item': instance.item,
  'qty': instance.qty,
};
