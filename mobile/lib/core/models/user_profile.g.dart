// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  role: json['role'] as String,
  phone: json['phone'] as String?,
  engineer: json['engineer'] == null
      ? null
      : EngineerProfile.fromJson(json['engineer'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'role': instance.role,
      'phone': instance.phone,
      'engineer': instance.engineer,
    };

_EngineerProfile _$EngineerProfileFromJson(Map<String, dynamic> json) =>
    _EngineerProfile(
      employeeCode: json['employee_code'] as String,
      status: json['status'] as String,
      skills: (json['skills'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxActiveJobs: (json['max_active_jobs'] as num).toInt(),
    );

Map<String, dynamic> _$EngineerProfileToJson(_EngineerProfile instance) =>
    <String, dynamic>{
      'employee_code': instance.employeeCode,
      'status': instance.status,
      'skills': instance.skills,
      'max_active_jobs': instance.maxActiveJobs,
    };
