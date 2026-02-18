// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
  id: (json['id'] as num?)?.toInt() ?? 0,
  userId: (json['userId'] as num?)?.toInt() ?? 0,
  notificationType: json['notificationType'] as String? ?? '',
  title: json['title'] as String? ?? '',
  message: json['message'] as String? ?? '',
  relatedEntityType: json['relatedEntityType'] as String?,
  relatedEntityId: (json['relatedEntityId'] as num?)?.toInt(),
  isRead: json['isRead'] as bool? ?? false,
  isSent: json['isSent'] as bool? ?? true,
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  userName: json['userName'] as String?,
);

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'notificationType': instance.notificationType,
      'title': instance.title,
      'message': instance.message,
      'relatedEntityType': instance.relatedEntityType,
      'relatedEntityId': instance.relatedEntityId,
      'isRead': instance.isRead,
      'isSent': instance.isSent,
      'sentAt': instance.sentAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'userName': instance.userName,
    };
