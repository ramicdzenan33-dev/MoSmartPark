import 'package:flutter/material.dart';
import 'package:mosmartpark_desktop/model/notification.dart' as model;
import 'package:mosmartpark_desktop/providers/notification_provider.dart';
import 'package:mosmartpark_desktop/providers/user_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final NotificationProvider _notificationProvider = NotificationProvider();
  List<model.Notification> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (UserProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var result = await _notificationProvider.get(
        filter: {
          'UserId': UserProvider.currentUser!.id,
          'PageSize': 20,
          'Page': 0,
        },
      );

      setState(() {
        _notifications = result.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(model.Notification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationProvider.markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllAsRead() async {
    if (UserProvider.currentUser == null) return;

    try {
      await _notificationProvider.markAllAsRead(UserProvider.currentUser!.id);
      await _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_reservation':
        return Icons.event_note;
      case 'new_review':
        return Icons.rate_review;
      case 'new_car':
        return Icons.directions_car;
      case 'car_updated':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_reservation':
        return const Color(0xFF3B82F6); // Blue
      case 'new_review':
        return const Color(0xFFFBBF24); // Yellow/Gold
      case 'new_car':
      case 'car_updated':
        return const Color(0xFF8B6F47); // Brown (brand color)
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B6F47),
                  const Color(0xFF8B6F47).withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (_notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Notifications List
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B6F47),
                      ),
                    ),
                  )
                : _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(model.Notification notification) {
    final color = _getNotificationColor(notification.notificationType);
    final icon = _getNotificationIcon(notification.notificationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _markAsRead(notification),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.grey[50]
                  : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isRead
                    ? Colors.grey[200]!
                    : color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
