// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UserProfile({
    required String id,
    required String fullName,
    required String role,
    String? phone,
    EngineerProfile? engineer,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
abstract class EngineerProfile with _$EngineerProfile {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EngineerProfile({
    required String employeeCode,
    required String status,
    required List<String> skills,
    required int maxActiveJobs,
  }) = _EngineerProfile;

  factory EngineerProfile.fromJson(Map<String, dynamic> json) =>
      _$EngineerProfileFromJson(json);
}
