import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final int id;
  final int userId;
  final String notificationType;
  final String title;
  final String message;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final bool isRead;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String? userName;

  Notification({
    this.id = 0,
    this.userId = 0,
    this.notificationType = '',
    this.title = '',
    this.message = '',
    this.relatedEntityType,
    this.relatedEntityId,
    this.isRead = false,
    this.isSent = true,
    this.sentAt,
    required this.createdAt,
    this.userName,
  });

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}
