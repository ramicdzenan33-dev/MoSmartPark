import 'package:mosmartpark_desktop/model/parking_spot.dart';
import 'package:mosmartpark_desktop/providers/base_provider.dart';

class ParkingSpotProvider extends BaseProvider<ParkingSpot> {
  ParkingSpotProvider() : super("ParkingSpot");

  @override
  ParkingSpot fromJson(dynamic json) {
    return ParkingSpot.fromJson(json);
  }
}

