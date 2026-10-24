// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    _DashboardStats(
      assignedCount: (json['assignedCount'] as num).toInt(),
      acceptedCount: (json['acceptedCount'] as num).toInt(),
      enRouteCount: (json['enRouteCount'] as num).toInt(),
      onSiteCount: (json['onSiteCount'] as num).toInt(),
      submittedCount: (json['submittedCount'] as num).toInt(),
      highPriorityCount: (json['highPriorityCount'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardStatsToJson(_DashboardStats instance) =>
    <String, dynamic>{
      'assignedCount': instance.assignedCount,
      'acceptedCount': instance.acceptedCount,
      'enRouteCount': instance.enRouteCount,
      'onSiteCount': instance.onSiteCount,
      'submittedCount': instance.submittedCount,
      'highPriorityCount': instance.highPriorityCount,
    };
