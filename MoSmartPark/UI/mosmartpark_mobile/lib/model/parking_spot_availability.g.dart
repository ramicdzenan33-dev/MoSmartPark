// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parking_spot_availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParkingSpotAvailability _$ParkingSpotAvailabilityFromJson(
  Map<String, dynamic> json,
) => ParkingSpotAvailability(
  id: (json['id'] as num?)?.toInt() ?? 0,
  parkingNumber: json['parkingNumber'] as String? ?? '',
  parkingSpotTypeName: json['parkingSpotTypeName'] as String? ?? '',
  parkingZoneId: (json['parkingZoneId'] as num?)?.toInt() ?? 0,
  parkingZoneName: json['parkingZoneName'] as String? ?? '',
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$ParkingSpotAvailabilityToJson(
  ParkingSpotAvailability instance,
) => <String, dynamic>{
  'id': instance.id,
  'parkingNumber': instance.parkingNumber,
  'parkingSpotTypeName': instance.parkingSpotTypeName,
  'parkingZoneId': instance.parkingZoneId,
  'parkingZoneName': instance.parkingZoneName,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'isAvailable': instance.isAvailable,
};
