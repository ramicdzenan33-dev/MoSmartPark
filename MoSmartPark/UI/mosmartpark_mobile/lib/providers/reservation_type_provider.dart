import 'package:mosmartpark_mobile/model/reservation_type.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class ReservationTypeProvider extends BaseProvider<ReservationType> {
  ReservationTypeProvider() : super("ReservationType");

  @override
  ReservationType fromJson(dynamic json) {
    return ReservationType.fromJson(json);
  }
}

