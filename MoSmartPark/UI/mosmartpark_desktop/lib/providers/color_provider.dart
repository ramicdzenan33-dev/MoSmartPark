import 'package:mosmartpark_desktop/model/color.dart';
import 'package:mosmartpark_desktop/providers/base_provider.dart';

class ColorProvider extends BaseProvider<CarColor> {
  ColorProvider() : super("Color");

  @override
  CarColor fromJson(dynamic json) {
    return CarColor.fromJson(json);
  }
}

