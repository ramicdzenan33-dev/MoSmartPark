import 'package:mosmartpark_mobile/model/car.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class CarProvider extends BaseProvider<Car> {
  CarProvider() : super("Car");

  @override
  Car fromJson(dynamic json) {
    return Car.fromJson(json);
  }
}

