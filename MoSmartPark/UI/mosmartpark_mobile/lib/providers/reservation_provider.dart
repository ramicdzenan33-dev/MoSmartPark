import 'package:mosmartpark_mobile/model/reservation.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class ReservationProvider extends BaseProvider<Reservation> {
  ReservationProvider() : super("Reservation");

  @override
  Reservation fromJson(dynamic json) {
    return Reservation.fromJson(json);
  }
}

