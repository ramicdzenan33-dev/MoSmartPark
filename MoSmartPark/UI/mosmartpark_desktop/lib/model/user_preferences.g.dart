// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      themeMode: json['themeMode'] as String? ?? 'system',
      defaultParkingZoneId: (json['defaultParkingZoneId'] as num?)?.toInt(),
      defaultParkingZoneName: json['defaultParkingZoneName'] as String?,
      notifyReviews: json['notifyReviews'] as bool? ?? true,
      notifyReservations: json['notifyReservations'] as bool? ?? true,
      notifyCars: json['notifyCars'] as bool? ?? true,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'themeMode': instance.themeMode,
      'defaultParkingZoneId': instance.defaultParkingZoneId,
      'defaultParkingZoneName': instance.defaultParkingZoneName,
      'notifyReviews': instance.notifyReviews,
      'notifyReservations': instance.notifyReservations,
      'notifyCars': instance.notifyCars,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
