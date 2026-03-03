import 'package:json_annotation/json_annotation.dart';

part 'parking_spot.g.dart';

@JsonSerializable()
class ParkingSpot {
  final int id;
  final String parkingNumber;
  final int parkingSpotTypeId;
  final String parkingSpotTypeName;
  final int parkingZoneId;
  final String parkingZoneName;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  ParkingSpot({
    this.id = 0,
    this.parkingNumber = '',
    this.parkingSpotTypeId = 0,
    this.parkingSpotTypeName = '',
    this.parkingZoneId = 0,
    this.parkingZoneName = '',
    this.isActive = true,
    this.latitude,
    this.longitude,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) =>
      _$ParkingSpotFromJson(json);
  Map<String, dynamic> toJson() => _$ParkingSpotToJson(this);
}
