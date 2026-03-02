import 'package:json_annotation/json_annotation.dart';

part 'parking_spot_availability.g.dart';

@JsonSerializable()
class ParkingSpotAvailability {
  final int id;
  final String parkingNumber;
  final String parkingSpotTypeName;
  final int parkingZoneId;
  final String parkingZoneName;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;

  ParkingSpotAvailability({
    this.id = 0,
    this.parkingNumber = '',
    this.parkingSpotTypeName = '',
    this.parkingZoneId = 0,
    this.parkingZoneName = '',
    this.latitude,
    this.longitude,
    this.isAvailable = true,
  });

  factory ParkingSpotAvailability.fromJson(Map<String, dynamic> json) =>
      _$ParkingSpotAvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$ParkingSpotAvailabilityToJson(this);
}
