import 'package:json_annotation/json_annotation.dart';

part 'user_preferences.g.dart';

@JsonSerializable()
class UserPreferences {
  final int id;
  final int userId;
  final String themeMode;
  final int? defaultParkingZoneId;
  final String? defaultParkingZoneName;
  final bool notifyReviews;
  final bool notifyReservations;
  final bool notifyCars;
  final DateTime? updatedAt;

  UserPreferences({
    this.id = 0,
    this.userId = 0,
    this.themeMode = 'system',
    this.defaultParkingZoneId,
    this.defaultParkingZoneName,
    this.notifyReviews = true,
    this.notifyReservations = true,
    this.notifyCars = true,
    this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}
