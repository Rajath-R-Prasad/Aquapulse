// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String get fullName; String get role; String? get phone; EngineerProfile? get engineer;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.engineer, engineer) || other.engineer == engineer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,role,phone,engineer);

@override
String toString() {
  return 'UserProfile(id: $id, fullName: $fullName, role: $role, phone: $phone, engineer: $engineer)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String role, String? phone, EngineerProfile? engineer
});


$EngineerProfileCopyWith<$Res>? get engineer;

}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? role = null,Object? phone = freezed,Object? engineer = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,engineer: freezed == engineer ? _self.engineer : engineer // ignore: cast_nullable_to_non_nullable
as EngineerProfile?,
  ));
}
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngineerProfileCopyWith<$Res>? get engineer {
    if (_self.engineer == null) {
    return null;
  }

  return $EngineerProfileCopyWith<$Res>(_self.engineer!, (value) {
    return _then(_self.copyWith(engineer: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String role,  String? phone,  EngineerProfile? engineer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.role,_that.phone,_that.engineer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String role,  String? phone,  EngineerProfile? engineer)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.fullName,_that.role,_that.phone,_that.engineer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String role,  String? phone,  EngineerProfile? engineer)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.fullName,_that.role,_that.phone,_that.engineer);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, required this.fullName, required this.role, this.phone, this.engineer});
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  String role;
@override final  String? phone;
@override final  EngineerProfile? engineer;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.engineer, engineer) || other.engineer == engineer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,role,phone,engineer);

@override
String toString() {
  return 'UserProfile(id: $id, fullName: $fullName, role: $role, phone: $phone, engineer: $engineer)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String role, String? phone, EngineerProfile? engineer
});


@override $EngineerProfileCopyWith<$Res>? get engineer;

}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? role = null,Object? phone = freezed,Object? engineer = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,engineer: freezed == engineer ? _self.engineer : engineer // ignore: cast_nullable_to_non_nullable
as EngineerProfile?,
  ));
}

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngineerProfileCopyWith<$Res>? get engineer {
    if (_self.engineer == null) {
    return null;
  }

  return $EngineerProfileCopyWith<$Res>(_self.engineer!, (value) {
    return _then(_self.copyWith(engineer: value));
  });
}
}


/// @nodoc
mixin _$EngineerProfile {

 String get employeeCode; String get status; List<String> get skills; int get maxActiveJobs;
/// Create a copy of EngineerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngineerProfileCopyWith<EngineerProfile> get copyWith => _$EngineerProfileCopyWithImpl<EngineerProfile>(this as EngineerProfile, _$identity);

  /// Serializes this EngineerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngineerProfile&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.skills, skills)&&(identical(other.maxActiveJobs, maxActiveJobs) || other.maxActiveJobs == maxActiveJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeCode,status,const DeepCollectionEquality().hash(skills),maxActiveJobs);

@override
String toString() {
  return 'EngineerProfile(employeeCode: $employeeCode, status: $status, skills: $skills, maxActiveJobs: $maxActiveJobs)';
}


}

/// @nodoc
abstract mixin class $EngineerProfileCopyWith<$Res>  {
  factory $EngineerProfileCopyWith(EngineerProfile value, $Res Function(EngineerProfile) _then) = _$EngineerProfileCopyWithImpl;
@useResult
$Res call({
 String employeeCode, String status, List<String> skills, int maxActiveJobs
});




}
/// @nodoc
class _$EngineerProfileCopyWithImpl<$Res>
    implements $EngineerProfileCopyWith<$Res> {
  _$EngineerProfileCopyWithImpl(this._self, this._then);

  final EngineerProfile _self;
  final $Res Function(EngineerProfile) _then;

/// Create a copy of EngineerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeCode = null,Object? status = null,Object? skills = null,Object? maxActiveJobs = null,}) {
  return _then(_self.copyWith(
employeeCode: null == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,maxActiveJobs: null == maxActiveJobs ? _self.maxActiveJobs : maxActiveJobs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EngineerProfile].
extension EngineerProfilePatterns on EngineerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EngineerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EngineerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EngineerProfile value)  $default,){
final _that = this;
switch (_that) {
case _EngineerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EngineerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _EngineerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String employeeCode,  String status,  List<String> skills,  int maxActiveJobs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EngineerProfile() when $default != null:
return $default(_that.employeeCode,_that.status,_that.skills,_that.maxActiveJobs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String employeeCode,  String status,  List<String> skills,  int maxActiveJobs)  $default,) {final _that = this;
switch (_that) {
case _EngineerProfile():
return $default(_that.employeeCode,_that.status,_that.skills,_that.maxActiveJobs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String employeeCode,  String status,  List<String> skills,  int maxActiveJobs)?  $default,) {final _that = this;
switch (_that) {
case _EngineerProfile() when $default != null:
return $default(_that.employeeCode,_that.status,_that.skills,_that.maxActiveJobs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _EngineerProfile implements EngineerProfile {
  const _EngineerProfile({required this.employeeCode, required this.status, required final  List<String> skills, required this.maxActiveJobs}): _skills = skills;
  factory _EngineerProfile.fromJson(Map<String, dynamic> json) => _$EngineerProfileFromJson(json);

@override final  String employeeCode;
@override final  String status;
 final  List<String> _skills;
@override List<String> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

@override final  int maxActiveJobs;

/// Create a copy of EngineerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngineerProfileCopyWith<_EngineerProfile> get copyWith => __$EngineerProfileCopyWithImpl<_EngineerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EngineerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngineerProfile&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._skills, _skills)&&(identical(other.maxActiveJobs, maxActiveJobs) || other.maxActiveJobs == maxActiveJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeCode,status,const DeepCollectionEquality().hash(_skills),maxActiveJobs);

@override
String toString() {
  return 'EngineerProfile(employeeCode: $employeeCode, status: $status, skills: $skills, maxActiveJobs: $maxActiveJobs)';
}


}

/// @nodoc
abstract mixin class _$EngineerProfileCopyWith<$Res> implements $EngineerProfileCopyWith<$Res> {
  factory _$EngineerProfileCopyWith(_EngineerProfile value, $Res Function(_EngineerProfile) _then) = __$EngineerProfileCopyWithImpl;
@override @useResult
$Res call({
 String employeeCode, String status, List<String> skills, int maxActiveJobs
});




}
/// @nodoc
class __$EngineerProfileCopyWithImpl<$Res>
    implements _$EngineerProfileCopyWith<$Res> {
  __$EngineerProfileCopyWithImpl(this._self, this._then);

  final _EngineerProfile _self;
  final $Res Function(_EngineerProfile) _then;

/// Create a copy of EngineerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeCode = null,Object? status = null,Object? skills = null,Object? maxActiveJobs = null,}) {
  return _then(_EngineerProfile(
employeeCode: null == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,maxActiveJobs: null == maxActiveJobs ? _self.maxActiveJobs : maxActiveJobs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
