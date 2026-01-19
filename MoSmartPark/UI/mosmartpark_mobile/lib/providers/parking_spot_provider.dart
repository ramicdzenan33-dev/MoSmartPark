import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mosmartpark_mobile/model/parking_spot.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class ParkingSpotProvider extends BaseProvider<ParkingSpot> {
  ParkingSpotProvider() : super("ParkingSpot");

  @override
  ParkingSpot fromJson(dynamic json) {
    return ParkingSpot.fromJson(json);
  }

  /// Get recommended parking spot for a user in a specific zone
  Future<ParkingSpot?> getRecommendation(
    int userId,
    int parkingZoneId, {
    int? reservationTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var baseUrl = BaseProvider.baseUrl ?? "http://10.0.2.2:5130/";
    var uri = Uri.parse("$baseUrl$endpoint/recommend/$userId/$parkingZoneId").replace(
      queryParameters: {
        if (reservationTypeId != null) 'reservationTypeId': reservationTypeId.toString(),
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      if (response.body.isEmpty) return null;
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      return null;
    }
  }
}

