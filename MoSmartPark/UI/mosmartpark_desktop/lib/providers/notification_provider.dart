import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mosmartpark_desktop/model/notification.dart' as model;
import 'package:mosmartpark_desktop/providers/base_provider.dart';

class NotificationProvider extends BaseProvider<model.Notification> {
  NotificationProvider() : super("Notification");

  @override
  model.Notification fromJson(data) {
    return model.Notification.fromJson(data);
  }

  Future<int> getUnreadCount(int userId) async {
    var url = "${BaseProvider.baseUrl}Notification/unread-count/$userId";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return data['count'] ?? 0;
    }

    throw Exception("Failed to get unread count");
  }

  Future<void> markAsRead(int notificationId) async {
    var url =
        "${BaseProvider.baseUrl}Notification/$notificationId/mark-as-read";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    await http.put(uri, headers: headers);
  }

  Future<void> markAllAsRead(int userId) async {
    var url =
        "${BaseProvider.baseUrl}Notification/user/$userId/mark-all-as-read";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    await http.put(uri, headers: headers);
  }
}
