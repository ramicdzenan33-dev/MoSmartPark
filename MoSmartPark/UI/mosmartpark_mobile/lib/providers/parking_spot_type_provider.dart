import 'package:mosmartpark_mobile/model/parking_spot_type.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class ParkingSpotTypeProvider extends BaseProvider<ParkingSpotType> {
  ParkingSpotTypeProvider() : super("ParkingSpotType");

  @override
  ParkingSpotType fromJson(dynamic json) {
    return ParkingSpotType.fromJson(json);
  }
}

