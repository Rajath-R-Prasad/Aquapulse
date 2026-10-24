// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkOrder {

 String get id; String get woNo; String get status; String get priority; DateTime? get slaDueAt; DateTime? get assignedAt; DateTime? get acceptedAt; DateTime? get arrivedAt; String? get rejectionReason; DateTime get createdAt; String get leakEventId; String get eventNo; String get severity; String get source; bool get isSimulated; String get pipeCode; double get lon; double get lat;
/// Create a copy of WorkOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkOrderCopyWith<WorkOrder> get copyWith => _$WorkOrderCopyWithImpl<WorkOrder>(this as WorkOrder, _$identity);

  /// Serializes this WorkOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.woNo, woNo) || other.woNo == woNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.slaDueAt, slaDueAt) || other.slaDueAt == slaDueAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.leakEventId, leakEventId) || other.leakEventId == leakEventId)&&(identical(other.eventNo, eventNo) || other.eventNo == eventNo)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.source, source) || other.source == source)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated)&&(identical(other.pipeCode, pipeCode) || other.pipeCode == pipeCode)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,woNo,status,priority,slaDueAt,assignedAt,acceptedAt,arrivedAt,rejectionReason,createdAt,leakEventId,eventNo,severity,source,isSimulated,pipeCode,lon,lat);

@override
String toString() {
  return 'WorkOrder(id: $id, woNo: $woNo, status: $status, priority: $priority, slaDueAt: $slaDueAt, assignedAt: $assignedAt, acceptedAt: $acceptedAt, arrivedAt: $arrivedAt, rejectionReason: $rejectionReason, createdAt: $createdAt, leakEventId: $leakEventId, eventNo: $eventNo, severity: $severity, source: $source, isSimulated: $isSimulated, pipeCode: $pipeCode, lon: $lon, lat: $lat)';
}


}

/// @nodoc
abstract mixin class $WorkOrderCopyWith<$Res>  {
  factory $WorkOrderCopyWith(WorkOrder value, $Res Function(WorkOrder) _then) = _$WorkOrderCopyWithImpl;
@useResult
$Res call({
 String id, String woNo, String status, String priority, DateTime? slaDueAt, DateTime? assignedAt, DateTime? acceptedAt, DateTime? arrivedAt, String? rejectionReason, DateTime createdAt, String leakEventId, String eventNo, String severity, String source, bool isSimulated, String pipeCode, double lon, double lat
});




}
/// @nodoc
class _$WorkOrderCopyWithImpl<$Res>
    implements $WorkOrderCopyWith<$Res> {
  _$WorkOrderCopyWithImpl(this._self, this._then);

  final WorkOrder _self;
  final $Res Function(WorkOrder) _then;

/// Create a copy of WorkOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? woNo = null,Object? status = null,Object? priority = null,Object? slaDueAt = freezed,Object? assignedAt = freezed,Object? acceptedAt = freezed,Object? arrivedAt = freezed,Object? rejectionReason = freezed,Object? createdAt = null,Object? leakEventId = null,Object? eventNo = null,Object? severity = null,Object? source = null,Object? isSimulated = null,Object? pipeCode = null,Object? lon = null,Object? lat = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,woNo: null == woNo ? _self.woNo : woNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,slaDueAt: freezed == slaDueAt ? _self.slaDueAt : slaDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,leakEventId: null == leakEventId ? _self.leakEventId : leakEventId // ignore: cast_nullable_to_non_nullable
as String,eventNo: null == eventNo ? _self.eventNo : eventNo // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,pipeCode: null == pipeCode ? _self.pipeCode : pipeCode // ignore: cast_nullable_to_non_nullable
as String,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkOrder].
extension WorkOrderPatterns on WorkOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkOrder value)  $default,){
final _that = this;
switch (_that) {
case _WorkOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkOrder value)?  $default,){
final _that = this;
switch (_that) {
case _WorkOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? arrivedAt,  String? rejectionReason,  DateTime createdAt,  String leakEventId,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkOrder() when $default != null:
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.arrivedAt,_that.rejectionReason,_that.createdAt,_that.leakEventId,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? arrivedAt,  String? rejectionReason,  DateTime createdAt,  String leakEventId,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat)  $default,) {final _that = this;
switch (_that) {
case _WorkOrder():
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.arrivedAt,_that.rejectionReason,_that.createdAt,_that.leakEventId,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? arrivedAt,  String? rejectionReason,  DateTime createdAt,  String leakEventId,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat)?  $default,) {final _that = this;
switch (_that) {
case _WorkOrder() when $default != null:
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.arrivedAt,_that.rejectionReason,_that.createdAt,_that.leakEventId,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkOrder implements WorkOrder {
  const _WorkOrder({required this.id, required this.woNo, required this.status, required this.priority, this.slaDueAt, this.assignedAt, this.acceptedAt, this.arrivedAt, this.rejectionReason, required this.createdAt, required this.leakEventId, required this.eventNo, required this.severity, required this.source, required this.isSimulated, required this.pipeCode, required this.lon, required this.lat});
  factory _WorkOrder.fromJson(Map<String, dynamic> json) => _$WorkOrderFromJson(json);

@override final  String id;
@override final  String woNo;
@override final  String status;
@override final  String priority;
@override final  DateTime? slaDueAt;
@override final  DateTime? assignedAt;
@override final  DateTime? acceptedAt;
@override final  DateTime? arrivedAt;
@override final  String? rejectionReason;
@override final  DateTime createdAt;
@override final  String leakEventId;
@override final  String eventNo;
@override final  String severity;
@override final  String source;
@override final  bool isSimulated;
@override final  String pipeCode;
@override final  double lon;
@override final  double lat;

/// Create a copy of WorkOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkOrderCopyWith<_WorkOrder> get copyWith => __$WorkOrderCopyWithImpl<_WorkOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.woNo, woNo) || other.woNo == woNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.slaDueAt, slaDueAt) || other.slaDueAt == slaDueAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.leakEventId, leakEventId) || other.leakEventId == leakEventId)&&(identical(other.eventNo, eventNo) || other.eventNo == eventNo)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.source, source) || other.source == source)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated)&&(identical(other.pipeCode, pipeCode) || other.pipeCode == pipeCode)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,woNo,status,priority,slaDueAt,assignedAt,acceptedAt,arrivedAt,rejectionReason,createdAt,leakEventId,eventNo,severity,source,isSimulated,pipeCode,lon,lat);

@override
String toString() {
  return 'WorkOrder(id: $id, woNo: $woNo, status: $status, priority: $priority, slaDueAt: $slaDueAt, assignedAt: $assignedAt, acceptedAt: $acceptedAt, arrivedAt: $arrivedAt, rejectionReason: $rejectionReason, createdAt: $createdAt, leakEventId: $leakEventId, eventNo: $eventNo, severity: $severity, source: $source, isSimulated: $isSimulated, pipeCode: $pipeCode, lon: $lon, lat: $lat)';
}


}

/// @nodoc
abstract mixin class _$WorkOrderCopyWith<$Res> implements $WorkOrderCopyWith<$Res> {
  factory _$WorkOrderCopyWith(_WorkOrder value, $Res Function(_WorkOrder) _then) = __$WorkOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String woNo, String status, String priority, DateTime? slaDueAt, DateTime? assignedAt, DateTime? acceptedAt, DateTime? arrivedAt, String? rejectionReason, DateTime createdAt, String leakEventId, String eventNo, String severity, String source, bool isSimulated, String pipeCode, double lon, double lat
});




}
/// @nodoc
class __$WorkOrderCopyWithImpl<$Res>
    implements _$WorkOrderCopyWith<$Res> {
  __$WorkOrderCopyWithImpl(this._self, this._then);

  final _WorkOrder _self;
  final $Res Function(_WorkOrder) _then;

/// Create a copy of WorkOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? woNo = null,Object? status = null,Object? priority = null,Object? slaDueAt = freezed,Object? assignedAt = freezed,Object? acceptedAt = freezed,Object? arrivedAt = freezed,Object? rejectionReason = freezed,Object? createdAt = null,Object? leakEventId = null,Object? eventNo = null,Object? severity = null,Object? source = null,Object? isSimulated = null,Object? pipeCode = null,Object? lon = null,Object? lat = null,}) {
  return _then(_WorkOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,woNo: null == woNo ? _self.woNo : woNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,slaDueAt: freezed == slaDueAt ? _self.slaDueAt : slaDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,leakEventId: null == leakEventId ? _self.leakEventId : leakEventId // ignore: cast_nullable_to_non_nullable
as String,eventNo: null == eventNo ? _self.eventNo : eventNo // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,pipeCode: null == pipeCode ? _self.pipeCode : pipeCode // ignore: cast_nullable_to_non_nullable
as String,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$WorkOrderDetail {

 String get id; String get woNo; String get status; String get priority; DateTime? get slaDueAt; DateTime? get assignedAt; DateTime? get acceptedAt; DateTime? get enRouteAt; DateTime? get arrivedAt; DateTime? get submittedAt; DateTime? get approvedAt; String? get rejectionReason; String? get cancellationReason; String? get approvalComment; DateTime get createdAt; LeakEventInfo get leakEvent; List<RepairEvidence>? get evidence; RepairDetails? get repairDetails;
/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkOrderDetailCopyWith<WorkOrderDetail> get copyWith => _$WorkOrderDetailCopyWithImpl<WorkOrderDetail>(this as WorkOrderDetail, _$identity);

  /// Serializes this WorkOrderDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkOrderDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.woNo, woNo) || other.woNo == woNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.slaDueAt, slaDueAt) || other.slaDueAt == slaDueAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteAt, enRouteAt) || other.enRouteAt == enRouteAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.approvalComment, approvalComment) || other.approvalComment == approvalComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.leakEvent, leakEvent) || other.leakEvent == leakEvent)&&const DeepCollectionEquality().equals(other.evidence, evidence)&&(identical(other.repairDetails, repairDetails) || other.repairDetails == repairDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,woNo,status,priority,slaDueAt,assignedAt,acceptedAt,enRouteAt,arrivedAt,submittedAt,approvedAt,rejectionReason,cancellationReason,approvalComment,createdAt,leakEvent,const DeepCollectionEquality().hash(evidence),repairDetails);

@override
String toString() {
  return 'WorkOrderDetail(id: $id, woNo: $woNo, status: $status, priority: $priority, slaDueAt: $slaDueAt, assignedAt: $assignedAt, acceptedAt: $acceptedAt, enRouteAt: $enRouteAt, arrivedAt: $arrivedAt, submittedAt: $submittedAt, approvedAt: $approvedAt, rejectionReason: $rejectionReason, cancellationReason: $cancellationReason, approvalComment: $approvalComment, createdAt: $createdAt, leakEvent: $leakEvent, evidence: $evidence, repairDetails: $repairDetails)';
}


}

/// @nodoc
abstract mixin class $WorkOrderDetailCopyWith<$Res>  {
  factory $WorkOrderDetailCopyWith(WorkOrderDetail value, $Res Function(WorkOrderDetail) _then) = _$WorkOrderDetailCopyWithImpl;
@useResult
$Res call({
 String id, String woNo, String status, String priority, DateTime? slaDueAt, DateTime? assignedAt, DateTime? acceptedAt, DateTime? enRouteAt, DateTime? arrivedAt, DateTime? submittedAt, DateTime? approvedAt, String? rejectionReason, String? cancellationReason, String? approvalComment, DateTime createdAt, LeakEventInfo leakEvent, List<RepairEvidence>? evidence, RepairDetails? repairDetails
});


$LeakEventInfoCopyWith<$Res> get leakEvent;$RepairDetailsCopyWith<$Res>? get repairDetails;

}
/// @nodoc
class _$WorkOrderDetailCopyWithImpl<$Res>
    implements $WorkOrderDetailCopyWith<$Res> {
  _$WorkOrderDetailCopyWithImpl(this._self, this._then);

  final WorkOrderDetail _self;
  final $Res Function(WorkOrderDetail) _then;

/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? woNo = null,Object? status = null,Object? priority = null,Object? slaDueAt = freezed,Object? assignedAt = freezed,Object? acceptedAt = freezed,Object? enRouteAt = freezed,Object? arrivedAt = freezed,Object? submittedAt = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? cancellationReason = freezed,Object? approvalComment = freezed,Object? createdAt = null,Object? leakEvent = null,Object? evidence = freezed,Object? repairDetails = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,woNo: null == woNo ? _self.woNo : woNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,slaDueAt: freezed == slaDueAt ? _self.slaDueAt : slaDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,enRouteAt: freezed == enRouteAt ? _self.enRouteAt : enRouteAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,approvalComment: freezed == approvalComment ? _self.approvalComment : approvalComment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,leakEvent: null == leakEvent ? _self.leakEvent : leakEvent // ignore: cast_nullable_to_non_nullable
as LeakEventInfo,evidence: freezed == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<RepairEvidence>?,repairDetails: freezed == repairDetails ? _self.repairDetails : repairDetails // ignore: cast_nullable_to_non_nullable
as RepairDetails?,
  ));
}
/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeakEventInfoCopyWith<$Res> get leakEvent {
  
  return $LeakEventInfoCopyWith<$Res>(_self.leakEvent, (value) {
    return _then(_self.copyWith(leakEvent: value));
  });
}/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepairDetailsCopyWith<$Res>? get repairDetails {
    if (_self.repairDetails == null) {
    return null;
  }

  return $RepairDetailsCopyWith<$Res>(_self.repairDetails!, (value) {
    return _then(_self.copyWith(repairDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkOrderDetail].
extension WorkOrderDetailPatterns on WorkOrderDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkOrderDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkOrderDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkOrderDetail value)  $default,){
final _that = this;
switch (_that) {
case _WorkOrderDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkOrderDetail value)?  $default,){
final _that = this;
switch (_that) {
case _WorkOrderDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? enRouteAt,  DateTime? arrivedAt,  DateTime? submittedAt,  DateTime? approvedAt,  String? rejectionReason,  String? cancellationReason,  String? approvalComment,  DateTime createdAt,  LeakEventInfo leakEvent,  List<RepairEvidence>? evidence,  RepairDetails? repairDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkOrderDetail() when $default != null:
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.enRouteAt,_that.arrivedAt,_that.submittedAt,_that.approvedAt,_that.rejectionReason,_that.cancellationReason,_that.approvalComment,_that.createdAt,_that.leakEvent,_that.evidence,_that.repairDetails);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? enRouteAt,  DateTime? arrivedAt,  DateTime? submittedAt,  DateTime? approvedAt,  String? rejectionReason,  String? cancellationReason,  String? approvalComment,  DateTime createdAt,  LeakEventInfo leakEvent,  List<RepairEvidence>? evidence,  RepairDetails? repairDetails)  $default,) {final _that = this;
switch (_that) {
case _WorkOrderDetail():
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.enRouteAt,_that.arrivedAt,_that.submittedAt,_that.approvedAt,_that.rejectionReason,_that.cancellationReason,_that.approvalComment,_that.createdAt,_that.leakEvent,_that.evidence,_that.repairDetails);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String woNo,  String status,  String priority,  DateTime? slaDueAt,  DateTime? assignedAt,  DateTime? acceptedAt,  DateTime? enRouteAt,  DateTime? arrivedAt,  DateTime? submittedAt,  DateTime? approvedAt,  String? rejectionReason,  String? cancellationReason,  String? approvalComment,  DateTime createdAt,  LeakEventInfo leakEvent,  List<RepairEvidence>? evidence,  RepairDetails? repairDetails)?  $default,) {final _that = this;
switch (_that) {
case _WorkOrderDetail() when $default != null:
return $default(_that.id,_that.woNo,_that.status,_that.priority,_that.slaDueAt,_that.assignedAt,_that.acceptedAt,_that.enRouteAt,_that.arrivedAt,_that.submittedAt,_that.approvedAt,_that.rejectionReason,_that.cancellationReason,_that.approvalComment,_that.createdAt,_that.leakEvent,_that.evidence,_that.repairDetails);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkOrderDetail implements WorkOrderDetail {
  const _WorkOrderDetail({required this.id, required this.woNo, required this.status, required this.priority, this.slaDueAt, this.assignedAt, this.acceptedAt, this.enRouteAt, this.arrivedAt, this.submittedAt, this.approvedAt, this.rejectionReason, this.cancellationReason, this.approvalComment, required this.createdAt, required this.leakEvent, final  List<RepairEvidence>? evidence, this.repairDetails}): _evidence = evidence;
  factory _WorkOrderDetail.fromJson(Map<String, dynamic> json) => _$WorkOrderDetailFromJson(json);

@override final  String id;
@override final  String woNo;
@override final  String status;
@override final  String priority;
@override final  DateTime? slaDueAt;
@override final  DateTime? assignedAt;
@override final  DateTime? acceptedAt;
@override final  DateTime? enRouteAt;
@override final  DateTime? arrivedAt;
@override final  DateTime? submittedAt;
@override final  DateTime? approvedAt;
@override final  String? rejectionReason;
@override final  String? cancellationReason;
@override final  String? approvalComment;
@override final  DateTime createdAt;
@override final  LeakEventInfo leakEvent;
 final  List<RepairEvidence>? _evidence;
@override List<RepairEvidence>? get evidence {
  final value = _evidence;
  if (value == null) return null;
  if (_evidence is EqualUnmodifiableListView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  RepairDetails? repairDetails;

/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkOrderDetailCopyWith<_WorkOrderDetail> get copyWith => __$WorkOrderDetailCopyWithImpl<_WorkOrderDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkOrderDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkOrderDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.woNo, woNo) || other.woNo == woNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.slaDueAt, slaDueAt) || other.slaDueAt == slaDueAt)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteAt, enRouteAt) || other.enRouteAt == enRouteAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.approvalComment, approvalComment) || other.approvalComment == approvalComment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.leakEvent, leakEvent) || other.leakEvent == leakEvent)&&const DeepCollectionEquality().equals(other._evidence, _evidence)&&(identical(other.repairDetails, repairDetails) || other.repairDetails == repairDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,woNo,status,priority,slaDueAt,assignedAt,acceptedAt,enRouteAt,arrivedAt,submittedAt,approvedAt,rejectionReason,cancellationReason,approvalComment,createdAt,leakEvent,const DeepCollectionEquality().hash(_evidence),repairDetails);

@override
String toString() {
  return 'WorkOrderDetail(id: $id, woNo: $woNo, status: $status, priority: $priority, slaDueAt: $slaDueAt, assignedAt: $assignedAt, acceptedAt: $acceptedAt, enRouteAt: $enRouteAt, arrivedAt: $arrivedAt, submittedAt: $submittedAt, approvedAt: $approvedAt, rejectionReason: $rejectionReason, cancellationReason: $cancellationReason, approvalComment: $approvalComment, createdAt: $createdAt, leakEvent: $leakEvent, evidence: $evidence, repairDetails: $repairDetails)';
}


}

/// @nodoc
abstract mixin class _$WorkOrderDetailCopyWith<$Res> implements $WorkOrderDetailCopyWith<$Res> {
  factory _$WorkOrderDetailCopyWith(_WorkOrderDetail value, $Res Function(_WorkOrderDetail) _then) = __$WorkOrderDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String woNo, String status, String priority, DateTime? slaDueAt, DateTime? assignedAt, DateTime? acceptedAt, DateTime? enRouteAt, DateTime? arrivedAt, DateTime? submittedAt, DateTime? approvedAt, String? rejectionReason, String? cancellationReason, String? approvalComment, DateTime createdAt, LeakEventInfo leakEvent, List<RepairEvidence>? evidence, RepairDetails? repairDetails
});


@override $LeakEventInfoCopyWith<$Res> get leakEvent;@override $RepairDetailsCopyWith<$Res>? get repairDetails;

}
/// @nodoc
class __$WorkOrderDetailCopyWithImpl<$Res>
    implements _$WorkOrderDetailCopyWith<$Res> {
  __$WorkOrderDetailCopyWithImpl(this._self, this._then);

  final _WorkOrderDetail _self;
  final $Res Function(_WorkOrderDetail) _then;

/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? woNo = null,Object? status = null,Object? priority = null,Object? slaDueAt = freezed,Object? assignedAt = freezed,Object? acceptedAt = freezed,Object? enRouteAt = freezed,Object? arrivedAt = freezed,Object? submittedAt = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? cancellationReason = freezed,Object? approvalComment = freezed,Object? createdAt = null,Object? leakEvent = null,Object? evidence = freezed,Object? repairDetails = freezed,}) {
  return _then(_WorkOrderDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,woNo: null == woNo ? _self.woNo : woNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,slaDueAt: freezed == slaDueAt ? _self.slaDueAt : slaDueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,enRouteAt: freezed == enRouteAt ? _self.enRouteAt : enRouteAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,approvalComment: freezed == approvalComment ? _self.approvalComment : approvalComment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,leakEvent: null == leakEvent ? _self.leakEvent : leakEvent // ignore: cast_nullable_to_non_nullable
as LeakEventInfo,evidence: freezed == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<RepairEvidence>?,repairDetails: freezed == repairDetails ? _self.repairDetails : repairDetails // ignore: cast_nullable_to_non_nullable
as RepairDetails?,
  ));
}

/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeakEventInfoCopyWith<$Res> get leakEvent {
  
  return $LeakEventInfoCopyWith<$Res>(_self.leakEvent, (value) {
    return _then(_self.copyWith(leakEvent: value));
  });
}/// Create a copy of WorkOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepairDetailsCopyWith<$Res>? get repairDetails {
    if (_self.repairDetails == null) {
    return null;
  }

  return $RepairDetailsCopyWith<$Res>(_self.repairDetails!, (value) {
    return _then(_self.copyWith(repairDetails: value));
  });
}
}


/// @nodoc
mixin _$LeakEventInfo {

 String get id; String get eventNo; String get severity; String get source; bool get isSimulated; String get pipeCode; double get lon; double get lat; double? get leakConfidence; double? get flowAnomalyScore; double? get pressureDropPa; double? get estimatedLeakRateLpm; double? get estimatedLossPct; double? get chainageM; DateTime? get detectedAt;
/// Create a copy of LeakEventInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeakEventInfoCopyWith<LeakEventInfo> get copyWith => _$LeakEventInfoCopyWithImpl<LeakEventInfo>(this as LeakEventInfo, _$identity);

  /// Serializes this LeakEventInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeakEventInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.eventNo, eventNo) || other.eventNo == eventNo)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.source, source) || other.source == source)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated)&&(identical(other.pipeCode, pipeCode) || other.pipeCode == pipeCode)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.leakConfidence, leakConfidence) || other.leakConfidence == leakConfidence)&&(identical(other.flowAnomalyScore, flowAnomalyScore) || other.flowAnomalyScore == flowAnomalyScore)&&(identical(other.pressureDropPa, pressureDropPa) || other.pressureDropPa == pressureDropPa)&&(identical(other.estimatedLeakRateLpm, estimatedLeakRateLpm) || other.estimatedLeakRateLpm == estimatedLeakRateLpm)&&(identical(other.estimatedLossPct, estimatedLossPct) || other.estimatedLossPct == estimatedLossPct)&&(identical(other.chainageM, chainageM) || other.chainageM == chainageM)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventNo,severity,source,isSimulated,pipeCode,lon,lat,leakConfidence,flowAnomalyScore,pressureDropPa,estimatedLeakRateLpm,estimatedLossPct,chainageM,detectedAt);

@override
String toString() {
  return 'LeakEventInfo(id: $id, eventNo: $eventNo, severity: $severity, source: $source, isSimulated: $isSimulated, pipeCode: $pipeCode, lon: $lon, lat: $lat, leakConfidence: $leakConfidence, flowAnomalyScore: $flowAnomalyScore, pressureDropPa: $pressureDropPa, estimatedLeakRateLpm: $estimatedLeakRateLpm, estimatedLossPct: $estimatedLossPct, chainageM: $chainageM, detectedAt: $detectedAt)';
}


}

/// @nodoc
abstract mixin class $LeakEventInfoCopyWith<$Res>  {
  factory $LeakEventInfoCopyWith(LeakEventInfo value, $Res Function(LeakEventInfo) _then) = _$LeakEventInfoCopyWithImpl;
@useResult
$Res call({
 String id, String eventNo, String severity, String source, bool isSimulated, String pipeCode, double lon, double lat, double? leakConfidence, double? flowAnomalyScore, double? pressureDropPa, double? estimatedLeakRateLpm, double? estimatedLossPct, double? chainageM, DateTime? detectedAt
});




}
/// @nodoc
class _$LeakEventInfoCopyWithImpl<$Res>
    implements $LeakEventInfoCopyWith<$Res> {
  _$LeakEventInfoCopyWithImpl(this._self, this._then);

  final LeakEventInfo _self;
  final $Res Function(LeakEventInfo) _then;

/// Create a copy of LeakEventInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventNo = null,Object? severity = null,Object? source = null,Object? isSimulated = null,Object? pipeCode = null,Object? lon = null,Object? lat = null,Object? leakConfidence = freezed,Object? flowAnomalyScore = freezed,Object? pressureDropPa = freezed,Object? estimatedLeakRateLpm = freezed,Object? estimatedLossPct = freezed,Object? chainageM = freezed,Object? detectedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventNo: null == eventNo ? _self.eventNo : eventNo // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,pipeCode: null == pipeCode ? _self.pipeCode : pipeCode // ignore: cast_nullable_to_non_nullable
as String,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,leakConfidence: freezed == leakConfidence ? _self.leakConfidence : leakConfidence // ignore: cast_nullable_to_non_nullable
as double?,flowAnomalyScore: freezed == flowAnomalyScore ? _self.flowAnomalyScore : flowAnomalyScore // ignore: cast_nullable_to_non_nullable
as double?,pressureDropPa: freezed == pressureDropPa ? _self.pressureDropPa : pressureDropPa // ignore: cast_nullable_to_non_nullable
as double?,estimatedLeakRateLpm: freezed == estimatedLeakRateLpm ? _self.estimatedLeakRateLpm : estimatedLeakRateLpm // ignore: cast_nullable_to_non_nullable
as double?,estimatedLossPct: freezed == estimatedLossPct ? _self.estimatedLossPct : estimatedLossPct // ignore: cast_nullable_to_non_nullable
as double?,chainageM: freezed == chainageM ? _self.chainageM : chainageM // ignore: cast_nullable_to_non_nullable
as double?,detectedAt: freezed == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeakEventInfo].
extension LeakEventInfoPatterns on LeakEventInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeakEventInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeakEventInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeakEventInfo value)  $default,){
final _that = this;
switch (_that) {
case _LeakEventInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeakEventInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LeakEventInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat,  double? leakConfidence,  double? flowAnomalyScore,  double? pressureDropPa,  double? estimatedLeakRateLpm,  double? estimatedLossPct,  double? chainageM,  DateTime? detectedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeakEventInfo() when $default != null:
return $default(_that.id,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat,_that.leakConfidence,_that.flowAnomalyScore,_that.pressureDropPa,_that.estimatedLeakRateLpm,_that.estimatedLossPct,_that.chainageM,_that.detectedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat,  double? leakConfidence,  double? flowAnomalyScore,  double? pressureDropPa,  double? estimatedLeakRateLpm,  double? estimatedLossPct,  double? chainageM,  DateTime? detectedAt)  $default,) {final _that = this;
switch (_that) {
case _LeakEventInfo():
return $default(_that.id,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat,_that.leakConfidence,_that.flowAnomalyScore,_that.pressureDropPa,_that.estimatedLeakRateLpm,_that.estimatedLossPct,_that.chainageM,_that.detectedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventNo,  String severity,  String source,  bool isSimulated,  String pipeCode,  double lon,  double lat,  double? leakConfidence,  double? flowAnomalyScore,  double? pressureDropPa,  double? estimatedLeakRateLpm,  double? estimatedLossPct,  double? chainageM,  DateTime? detectedAt)?  $default,) {final _that = this;
switch (_that) {
case _LeakEventInfo() when $default != null:
return $default(_that.id,_that.eventNo,_that.severity,_that.source,_that.isSimulated,_that.pipeCode,_that.lon,_that.lat,_that.leakConfidence,_that.flowAnomalyScore,_that.pressureDropPa,_that.estimatedLeakRateLpm,_that.estimatedLossPct,_that.chainageM,_that.detectedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _LeakEventInfo implements LeakEventInfo {
  const _LeakEventInfo({required this.id, required this.eventNo, required this.severity, required this.source, required this.isSimulated, required this.pipeCode, required this.lon, required this.lat, this.leakConfidence, this.flowAnomalyScore, this.pressureDropPa, this.estimatedLeakRateLpm, this.estimatedLossPct, this.chainageM, this.detectedAt});
  factory _LeakEventInfo.fromJson(Map<String, dynamic> json) => _$LeakEventInfoFromJson(json);

@override final  String id;
@override final  String eventNo;
@override final  String severity;
@override final  String source;
@override final  bool isSimulated;
@override final  String pipeCode;
@override final  double lon;
@override final  double lat;
@override final  double? leakConfidence;
@override final  double? flowAnomalyScore;
@override final  double? pressureDropPa;
@override final  double? estimatedLeakRateLpm;
@override final  double? estimatedLossPct;
@override final  double? chainageM;
@override final  DateTime? detectedAt;

/// Create a copy of LeakEventInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeakEventInfoCopyWith<_LeakEventInfo> get copyWith => __$LeakEventInfoCopyWithImpl<_LeakEventInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeakEventInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeakEventInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.eventNo, eventNo) || other.eventNo == eventNo)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.source, source) || other.source == source)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated)&&(identical(other.pipeCode, pipeCode) || other.pipeCode == pipeCode)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.leakConfidence, leakConfidence) || other.leakConfidence == leakConfidence)&&(identical(other.flowAnomalyScore, flowAnomalyScore) || other.flowAnomalyScore == flowAnomalyScore)&&(identical(other.pressureDropPa, pressureDropPa) || other.pressureDropPa == pressureDropPa)&&(identical(other.estimatedLeakRateLpm, estimatedLeakRateLpm) || other.estimatedLeakRateLpm == estimatedLeakRateLpm)&&(identical(other.estimatedLossPct, estimatedLossPct) || other.estimatedLossPct == estimatedLossPct)&&(identical(other.chainageM, chainageM) || other.chainageM == chainageM)&&(identical(other.detectedAt, detectedAt) || other.detectedAt == detectedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventNo,severity,source,isSimulated,pipeCode,lon,lat,leakConfidence,flowAnomalyScore,pressureDropPa,estimatedLeakRateLpm,estimatedLossPct,chainageM,detectedAt);

@override
String toString() {
  return 'LeakEventInfo(id: $id, eventNo: $eventNo, severity: $severity, source: $source, isSimulated: $isSimulated, pipeCode: $pipeCode, lon: $lon, lat: $lat, leakConfidence: $leakConfidence, flowAnomalyScore: $flowAnomalyScore, pressureDropPa: $pressureDropPa, estimatedLeakRateLpm: $estimatedLeakRateLpm, estimatedLossPct: $estimatedLossPct, chainageM: $chainageM, detectedAt: $detectedAt)';
}


}

/// @nodoc
abstract mixin class _$LeakEventInfoCopyWith<$Res> implements $LeakEventInfoCopyWith<$Res> {
  factory _$LeakEventInfoCopyWith(_LeakEventInfo value, $Res Function(_LeakEventInfo) _then) = __$LeakEventInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventNo, String severity, String source, bool isSimulated, String pipeCode, double lon, double lat, double? leakConfidence, double? flowAnomalyScore, double? pressureDropPa, double? estimatedLeakRateLpm, double? estimatedLossPct, double? chainageM, DateTime? detectedAt
});




}
/// @nodoc
class __$LeakEventInfoCopyWithImpl<$Res>
    implements _$LeakEventInfoCopyWith<$Res> {
  __$LeakEventInfoCopyWithImpl(this._self, this._then);

  final _LeakEventInfo _self;
  final $Res Function(_LeakEventInfo) _then;

/// Create a copy of LeakEventInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventNo = null,Object? severity = null,Object? source = null,Object? isSimulated = null,Object? pipeCode = null,Object? lon = null,Object? lat = null,Object? leakConfidence = freezed,Object? flowAnomalyScore = freezed,Object? pressureDropPa = freezed,Object? estimatedLeakRateLpm = freezed,Object? estimatedLossPct = freezed,Object? chainageM = freezed,Object? detectedAt = freezed,}) {
  return _then(_LeakEventInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventNo: null == eventNo ? _self.eventNo : eventNo // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,pipeCode: null == pipeCode ? _self.pipeCode : pipeCode // ignore: cast_nullable_to_non_nullable
as String,lon: null == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,leakConfidence: freezed == leakConfidence ? _self.leakConfidence : leakConfidence // ignore: cast_nullable_to_non_nullable
as double?,flowAnomalyScore: freezed == flowAnomalyScore ? _self.flowAnomalyScore : flowAnomalyScore // ignore: cast_nullable_to_non_nullable
as double?,pressureDropPa: freezed == pressureDropPa ? _self.pressureDropPa : pressureDropPa // ignore: cast_nullable_to_non_nullable
as double?,estimatedLeakRateLpm: freezed == estimatedLeakRateLpm ? _self.estimatedLeakRateLpm : estimatedLeakRateLpm // ignore: cast_nullable_to_non_nullable
as double?,estimatedLossPct: freezed == estimatedLossPct ? _self.estimatedLossPct : estimatedLossPct // ignore: cast_nullable_to_non_nullable
as double?,chainageM: freezed == chainageM ? _self.chainageM : chainageM // ignore: cast_nullable_to_non_nullable
as double?,detectedAt: freezed == detectedAt ? _self.detectedAt : detectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$RepairEvidence {

 String get id; String get kind; String get storagePath; String get mimeType; int? get sizeBytes; DateTime? get capturedAt; double? get distanceToLeakM; bool? get geoValid; DateTime get createdAt; double? get lon; double? get lat; String? get url;
/// Create a copy of RepairEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepairEvidenceCopyWith<RepairEvidence> get copyWith => _$RepairEvidenceCopyWithImpl<RepairEvidence>(this as RepairEvidence, _$identity);

  /// Serializes this RepairEvidence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepairEvidence&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.distanceToLeakM, distanceToLeakM) || other.distanceToLeakM == distanceToLeakM)&&(identical(other.geoValid, geoValid) || other.geoValid == geoValid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,storagePath,mimeType,sizeBytes,capturedAt,distanceToLeakM,geoValid,createdAt,lon,lat,url);

@override
String toString() {
  return 'RepairEvidence(id: $id, kind: $kind, storagePath: $storagePath, mimeType: $mimeType, sizeBytes: $sizeBytes, capturedAt: $capturedAt, distanceToLeakM: $distanceToLeakM, geoValid: $geoValid, createdAt: $createdAt, lon: $lon, lat: $lat, url: $url)';
}


}

/// @nodoc
abstract mixin class $RepairEvidenceCopyWith<$Res>  {
  factory $RepairEvidenceCopyWith(RepairEvidence value, $Res Function(RepairEvidence) _then) = _$RepairEvidenceCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String storagePath, String mimeType, int? sizeBytes, DateTime? capturedAt, double? distanceToLeakM, bool? geoValid, DateTime createdAt, double? lon, double? lat, String? url
});




}
/// @nodoc
class _$RepairEvidenceCopyWithImpl<$Res>
    implements $RepairEvidenceCopyWith<$Res> {
  _$RepairEvidenceCopyWithImpl(this._self, this._then);

  final RepairEvidence _self;
  final $Res Function(RepairEvidence) _then;

/// Create a copy of RepairEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? storagePath = null,Object? mimeType = null,Object? sizeBytes = freezed,Object? capturedAt = freezed,Object? distanceToLeakM = freezed,Object? geoValid = freezed,Object? createdAt = null,Object? lon = freezed,Object? lat = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,distanceToLeakM: freezed == distanceToLeakM ? _self.distanceToLeakM : distanceToLeakM // ignore: cast_nullable_to_non_nullable
as double?,geoValid: freezed == geoValid ? _self.geoValid : geoValid // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RepairEvidence].
extension RepairEvidencePatterns on RepairEvidence {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepairEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepairEvidence() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepairEvidence value)  $default,){
final _that = this;
switch (_that) {
case _RepairEvidence():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepairEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _RepairEvidence() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String storagePath,  String mimeType,  int? sizeBytes,  DateTime? capturedAt,  double? distanceToLeakM,  bool? geoValid,  DateTime createdAt,  double? lon,  double? lat,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepairEvidence() when $default != null:
return $default(_that.id,_that.kind,_that.storagePath,_that.mimeType,_that.sizeBytes,_that.capturedAt,_that.distanceToLeakM,_that.geoValid,_that.createdAt,_that.lon,_that.lat,_that.url);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String storagePath,  String mimeType,  int? sizeBytes,  DateTime? capturedAt,  double? distanceToLeakM,  bool? geoValid,  DateTime createdAt,  double? lon,  double? lat,  String? url)  $default,) {final _that = this;
switch (_that) {
case _RepairEvidence():
return $default(_that.id,_that.kind,_that.storagePath,_that.mimeType,_that.sizeBytes,_that.capturedAt,_that.distanceToLeakM,_that.geoValid,_that.createdAt,_that.lon,_that.lat,_that.url);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String storagePath,  String mimeType,  int? sizeBytes,  DateTime? capturedAt,  double? distanceToLeakM,  bool? geoValid,  DateTime createdAt,  double? lon,  double? lat,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _RepairEvidence() when $default != null:
return $default(_that.id,_that.kind,_that.storagePath,_that.mimeType,_that.sizeBytes,_that.capturedAt,_that.distanceToLeakM,_that.geoValid,_that.createdAt,_that.lon,_that.lat,_that.url);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _RepairEvidence implements RepairEvidence {
  const _RepairEvidence({required this.id, required this.kind, required this.storagePath, required this.mimeType, this.sizeBytes, this.capturedAt, this.distanceToLeakM, this.geoValid, required this.createdAt, this.lon, this.lat, this.url});
  factory _RepairEvidence.fromJson(Map<String, dynamic> json) => _$RepairEvidenceFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String storagePath;
@override final  String mimeType;
@override final  int? sizeBytes;
@override final  DateTime? capturedAt;
@override final  double? distanceToLeakM;
@override final  bool? geoValid;
@override final  DateTime createdAt;
@override final  double? lon;
@override final  double? lat;
@override final  String? url;

/// Create a copy of RepairEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepairEvidenceCopyWith<_RepairEvidence> get copyWith => __$RepairEvidenceCopyWithImpl<_RepairEvidence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepairEvidenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepairEvidence&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.distanceToLeakM, distanceToLeakM) || other.distanceToLeakM == distanceToLeakM)&&(identical(other.geoValid, geoValid) || other.geoValid == geoValid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,storagePath,mimeType,sizeBytes,capturedAt,distanceToLeakM,geoValid,createdAt,lon,lat,url);

@override
String toString() {
  return 'RepairEvidence(id: $id, kind: $kind, storagePath: $storagePath, mimeType: $mimeType, sizeBytes: $sizeBytes, capturedAt: $capturedAt, distanceToLeakM: $distanceToLeakM, geoValid: $geoValid, createdAt: $createdAt, lon: $lon, lat: $lat, url: $url)';
}


}

/// @nodoc
abstract mixin class _$RepairEvidenceCopyWith<$Res> implements $RepairEvidenceCopyWith<$Res> {
  factory _$RepairEvidenceCopyWith(_RepairEvidence value, $Res Function(_RepairEvidence) _then) = __$RepairEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String storagePath, String mimeType, int? sizeBytes, DateTime? capturedAt, double? distanceToLeakM, bool? geoValid, DateTime createdAt, double? lon, double? lat, String? url
});




}
/// @nodoc
class __$RepairEvidenceCopyWithImpl<$Res>
    implements _$RepairEvidenceCopyWith<$Res> {
  __$RepairEvidenceCopyWithImpl(this._self, this._then);

  final _RepairEvidence _self;
  final $Res Function(_RepairEvidence) _then;

/// Create a copy of RepairEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? storagePath = null,Object? mimeType = null,Object? sizeBytes = freezed,Object? capturedAt = freezed,Object? distanceToLeakM = freezed,Object? geoValid = freezed,Object? createdAt = null,Object? lon = freezed,Object? lat = freezed,Object? url = freezed,}) {
  return _then(_RepairEvidence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,distanceToLeakM: freezed == distanceToLeakM ? _self.distanceToLeakM : distanceToLeakM // ignore: cast_nullable_to_non_nullable
as double?,geoValid: freezed == geoValid ? _self.geoValid : geoValid // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RepairDetails {

 String get repairType; List<Material>? get materials; int? get labourMinutes; String? get workNotes;
/// Create a copy of RepairDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepairDetailsCopyWith<RepairDetails> get copyWith => _$RepairDetailsCopyWithImpl<RepairDetails>(this as RepairDetails, _$identity);

  /// Serializes this RepairDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepairDetails&&(identical(other.repairType, repairType) || other.repairType == repairType)&&const DeepCollectionEquality().equals(other.materials, materials)&&(identical(other.labourMinutes, labourMinutes) || other.labourMinutes == labourMinutes)&&(identical(other.workNotes, workNotes) || other.workNotes == workNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repairType,const DeepCollectionEquality().hash(materials),labourMinutes,workNotes);

@override
String toString() {
  return 'RepairDetails(repairType: $repairType, materials: $materials, labourMinutes: $labourMinutes, workNotes: $workNotes)';
}


}

/// @nodoc
abstract mixin class $RepairDetailsCopyWith<$Res>  {
  factory $RepairDetailsCopyWith(RepairDetails value, $Res Function(RepairDetails) _then) = _$RepairDetailsCopyWithImpl;
@useResult
$Res call({
 String repairType, List<Material>? materials, int? labourMinutes, String? workNotes
});




}
/// @nodoc
class _$RepairDetailsCopyWithImpl<$Res>
    implements $RepairDetailsCopyWith<$Res> {
  _$RepairDetailsCopyWithImpl(this._self, this._then);

  final RepairDetails _self;
  final $Res Function(RepairDetails) _then;

/// Create a copy of RepairDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repairType = null,Object? materials = freezed,Object? labourMinutes = freezed,Object? workNotes = freezed,}) {
  return _then(_self.copyWith(
repairType: null == repairType ? _self.repairType : repairType // ignore: cast_nullable_to_non_nullable
as String,materials: freezed == materials ? _self.materials : materials // ignore: cast_nullable_to_non_nullable
as List<Material>?,labourMinutes: freezed == labourMinutes ? _self.labourMinutes : labourMinutes // ignore: cast_nullable_to_non_nullable
as int?,workNotes: freezed == workNotes ? _self.workNotes : workNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RepairDetails].
extension RepairDetailsPatterns on RepairDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepairDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepairDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepairDetails value)  $default,){
final _that = this;
switch (_that) {
case _RepairDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepairDetails value)?  $default,){
final _that = this;
switch (_that) {
case _RepairDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String repairType,  List<Material>? materials,  int? labourMinutes,  String? workNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepairDetails() when $default != null:
return $default(_that.repairType,_that.materials,_that.labourMinutes,_that.workNotes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String repairType,  List<Material>? materials,  int? labourMinutes,  String? workNotes)  $default,) {final _that = this;
switch (_that) {
case _RepairDetails():
return $default(_that.repairType,_that.materials,_that.labourMinutes,_that.workNotes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String repairType,  List<Material>? materials,  int? labourMinutes,  String? workNotes)?  $default,) {final _that = this;
switch (_that) {
case _RepairDetails() when $default != null:
return $default(_that.repairType,_that.materials,_that.labourMinutes,_that.workNotes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _RepairDetails implements RepairDetails {
  const _RepairDetails({required this.repairType, final  List<Material>? materials, this.labourMinutes, this.workNotes}): _materials = materials;
  factory _RepairDetails.fromJson(Map<String, dynamic> json) => _$RepairDetailsFromJson(json);

@override final  String repairType;
 final  List<Material>? _materials;
@override List<Material>? get materials {
  final value = _materials;
  if (value == null) return null;
  if (_materials is EqualUnmodifiableListView) return _materials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? labourMinutes;
@override final  String? workNotes;

/// Create a copy of RepairDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepairDetailsCopyWith<_RepairDetails> get copyWith => __$RepairDetailsCopyWithImpl<_RepairDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepairDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepairDetails&&(identical(other.repairType, repairType) || other.repairType == repairType)&&const DeepCollectionEquality().equals(other._materials, _materials)&&(identical(other.labourMinutes, labourMinutes) || other.labourMinutes == labourMinutes)&&(identical(other.workNotes, workNotes) || other.workNotes == workNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repairType,const DeepCollectionEquality().hash(_materials),labourMinutes,workNotes);

@override
String toString() {
  return 'RepairDetails(repairType: $repairType, materials: $materials, labourMinutes: $labourMinutes, workNotes: $workNotes)';
}


}

/// @nodoc
abstract mixin class _$RepairDetailsCopyWith<$Res> implements $RepairDetailsCopyWith<$Res> {
  factory _$RepairDetailsCopyWith(_RepairDetails value, $Res Function(_RepairDetails) _then) = __$RepairDetailsCopyWithImpl;
@override @useResult
$Res call({
 String repairType, List<Material>? materials, int? labourMinutes, String? workNotes
});




}
/// @nodoc
class __$RepairDetailsCopyWithImpl<$Res>
    implements _$RepairDetailsCopyWith<$Res> {
  __$RepairDetailsCopyWithImpl(this._self, this._then);

  final _RepairDetails _self;
  final $Res Function(_RepairDetails) _then;

/// Create a copy of RepairDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repairType = null,Object? materials = freezed,Object? labourMinutes = freezed,Object? workNotes = freezed,}) {
  return _then(_RepairDetails(
repairType: null == repairType ? _self.repairType : repairType // ignore: cast_nullable_to_non_nullable
as String,materials: freezed == materials ? _self._materials : materials // ignore: cast_nullable_to_non_nullable
as List<Material>?,labourMinutes: freezed == labourMinutes ? _self.labourMinutes : labourMinutes // ignore: cast_nullable_to_non_nullable
as int?,workNotes: freezed == workNotes ? _self.workNotes : workNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Material {

 String get item; double get qty;
/// Create a copy of Material
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaterialCopyWith<Material> get copyWith => _$MaterialCopyWithImpl<Material>(this as Material, _$identity);

  /// Serializes this Material to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Material&&(identical(other.item, item) || other.item == item)&&(identical(other.qty, qty) || other.qty == qty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,qty);

@override
String toString() {
  return 'Material(item: $item, qty: $qty)';
}


}

/// @nodoc
abstract mixin class $MaterialCopyWith<$Res>  {
  factory $MaterialCopyWith(Material value, $Res Function(Material) _then) = _$MaterialCopyWithImpl;
@useResult
$Res call({
 String item, double qty
});




}
/// @nodoc
class _$MaterialCopyWithImpl<$Res>
    implements $MaterialCopyWith<$Res> {
  _$MaterialCopyWithImpl(this._self, this._then);

  final Material _self;
  final $Res Function(Material) _then;

/// Create a copy of Material
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? qty = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Material].
extension MaterialPatterns on Material {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Material value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Material() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Material value)  $default,){
final _that = this;
switch (_that) {
case _Material():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Material value)?  $default,){
final _that = this;
switch (_that) {
case _Material() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String item,  double qty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Material() when $default != null:
return $default(_that.item,_that.qty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String item,  double qty)  $default,) {final _that = this;
switch (_that) {
case _Material():
return $default(_that.item,_that.qty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String item,  double qty)?  $default,) {final _that = this;
switch (_that) {
case _Material() when $default != null:
return $default(_that.item,_that.qty);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Material implements Material {
  const _Material({required this.item, required this.qty});
  factory _Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);

@override final  String item;
@override final  double qty;

/// Create a copy of Material
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaterialCopyWith<_Material> get copyWith => __$MaterialCopyWithImpl<_Material>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Material&&(identical(other.item, item) || other.item == item)&&(identical(other.qty, qty) || other.qty == qty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,qty);

@override
String toString() {
  return 'Material(item: $item, qty: $qty)';
}


}

/// @nodoc
abstract mixin class _$MaterialCopyWith<$Res> implements $MaterialCopyWith<$Res> {
  factory _$MaterialCopyWith(_Material value, $Res Function(_Material) _then) = __$MaterialCopyWithImpl;
@override @useResult
$Res call({
 String item, double qty
});




}
/// @nodoc
class __$MaterialCopyWithImpl<$Res>
    implements _$MaterialCopyWith<$Res> {
  __$MaterialCopyWithImpl(this._self, this._then);

  final _Material _self;
  final $Res Function(_Material) _then;

/// Create a copy of Material
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? qty = null,}) {
  return _then(_Material(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
