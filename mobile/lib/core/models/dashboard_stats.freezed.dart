// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardStats {

 int get assignedCount; int get acceptedCount; int get enRouteCount; int get onSiteCount; int get submittedCount; int get highPriorityCount;
/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsCopyWith<DashboardStats> get copyWith => _$DashboardStatsCopyWithImpl<DashboardStats>(this as DashboardStats, _$identity);

  /// Serializes this DashboardStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStats&&(identical(other.assignedCount, assignedCount) || other.assignedCount == assignedCount)&&(identical(other.acceptedCount, acceptedCount) || other.acceptedCount == acceptedCount)&&(identical(other.enRouteCount, enRouteCount) || other.enRouteCount == enRouteCount)&&(identical(other.onSiteCount, onSiteCount) || other.onSiteCount == onSiteCount)&&(identical(other.submittedCount, submittedCount) || other.submittedCount == submittedCount)&&(identical(other.highPriorityCount, highPriorityCount) || other.highPriorityCount == highPriorityCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignedCount,acceptedCount,enRouteCount,onSiteCount,submittedCount,highPriorityCount);

@override
String toString() {
  return 'DashboardStats(assignedCount: $assignedCount, acceptedCount: $acceptedCount, enRouteCount: $enRouteCount, onSiteCount: $onSiteCount, submittedCount: $submittedCount, highPriorityCount: $highPriorityCount)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsCopyWith<$Res>  {
  factory $DashboardStatsCopyWith(DashboardStats value, $Res Function(DashboardStats) _then) = _$DashboardStatsCopyWithImpl;
@useResult
$Res call({
 int assignedCount, int acceptedCount, int enRouteCount, int onSiteCount, int submittedCount, int highPriorityCount
});




}
/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._self, this._then);

  final DashboardStats _self;
  final $Res Function(DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignedCount = null,Object? acceptedCount = null,Object? enRouteCount = null,Object? onSiteCount = null,Object? submittedCount = null,Object? highPriorityCount = null,}) {
  return _then(_self.copyWith(
assignedCount: null == assignedCount ? _self.assignedCount : assignedCount // ignore: cast_nullable_to_non_nullable
as int,acceptedCount: null == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as int,enRouteCount: null == enRouteCount ? _self.enRouteCount : enRouteCount // ignore: cast_nullable_to_non_nullable
as int,onSiteCount: null == onSiteCount ? _self.onSiteCount : onSiteCount // ignore: cast_nullable_to_non_nullable
as int,submittedCount: null == submittedCount ? _self.submittedCount : submittedCount // ignore: cast_nullable_to_non_nullable
as int,highPriorityCount: null == highPriorityCount ? _self.highPriorityCount : highPriorityCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStats].
extension DashboardStatsPatterns on DashboardStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStats value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStats value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int assignedCount,  int acceptedCount,  int enRouteCount,  int onSiteCount,  int submittedCount,  int highPriorityCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.assignedCount,_that.acceptedCount,_that.enRouteCount,_that.onSiteCount,_that.submittedCount,_that.highPriorityCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int assignedCount,  int acceptedCount,  int enRouteCount,  int onSiteCount,  int submittedCount,  int highPriorityCount)  $default,) {final _that = this;
switch (_that) {
case _DashboardStats():
return $default(_that.assignedCount,_that.acceptedCount,_that.enRouteCount,_that.onSiteCount,_that.submittedCount,_that.highPriorityCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int assignedCount,  int acceptedCount,  int enRouteCount,  int onSiteCount,  int submittedCount,  int highPriorityCount)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.assignedCount,_that.acceptedCount,_that.enRouteCount,_that.onSiteCount,_that.submittedCount,_that.highPriorityCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStats implements DashboardStats {
  const _DashboardStats({required this.assignedCount, required this.acceptedCount, required this.enRouteCount, required this.onSiteCount, required this.submittedCount, required this.highPriorityCount});
  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);

@override final  int assignedCount;
@override final  int acceptedCount;
@override final  int enRouteCount;
@override final  int onSiteCount;
@override final  int submittedCount;
@override final  int highPriorityCount;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsCopyWith<_DashboardStats> get copyWith => __$DashboardStatsCopyWithImpl<_DashboardStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStats&&(identical(other.assignedCount, assignedCount) || other.assignedCount == assignedCount)&&(identical(other.acceptedCount, acceptedCount) || other.acceptedCount == acceptedCount)&&(identical(other.enRouteCount, enRouteCount) || other.enRouteCount == enRouteCount)&&(identical(other.onSiteCount, onSiteCount) || other.onSiteCount == onSiteCount)&&(identical(other.submittedCount, submittedCount) || other.submittedCount == submittedCount)&&(identical(other.highPriorityCount, highPriorityCount) || other.highPriorityCount == highPriorityCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignedCount,acceptedCount,enRouteCount,onSiteCount,submittedCount,highPriorityCount);

@override
String toString() {
  return 'DashboardStats(assignedCount: $assignedCount, acceptedCount: $acceptedCount, enRouteCount: $enRouteCount, onSiteCount: $onSiteCount, submittedCount: $submittedCount, highPriorityCount: $highPriorityCount)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsCopyWith<$Res> implements $DashboardStatsCopyWith<$Res> {
  factory _$DashboardStatsCopyWith(_DashboardStats value, $Res Function(_DashboardStats) _then) = __$DashboardStatsCopyWithImpl;
@override @useResult
$Res call({
 int assignedCount, int acceptedCount, int enRouteCount, int onSiteCount, int submittedCount, int highPriorityCount
});




}
/// @nodoc
class __$DashboardStatsCopyWithImpl<$Res>
    implements _$DashboardStatsCopyWith<$Res> {
  __$DashboardStatsCopyWithImpl(this._self, this._then);

  final _DashboardStats _self;
  final $Res Function(_DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignedCount = null,Object? acceptedCount = null,Object? enRouteCount = null,Object? onSiteCount = null,Object? submittedCount = null,Object? highPriorityCount = null,}) {
  return _then(_DashboardStats(
assignedCount: null == assignedCount ? _self.assignedCount : assignedCount // ignore: cast_nullable_to_non_nullable
as int,acceptedCount: null == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as int,enRouteCount: null == enRouteCount ? _self.enRouteCount : enRouteCount // ignore: cast_nullable_to_non_nullable
as int,onSiteCount: null == onSiteCount ? _self.onSiteCount : onSiteCount // ignore: cast_nullable_to_non_nullable
as int,submittedCount: null == submittedCount ? _self.submittedCount : submittedCount // ignore: cast_nullable_to_non_nullable
as int,highPriorityCount: null == highPriorityCount ? _self.highPriorityCount : highPriorityCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
