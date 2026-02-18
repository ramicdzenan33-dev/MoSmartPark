import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mosmartpark_desktop/providers/notification_provider.dart';
import 'package:mosmartpark_desktop/providers/user_provider.dart';
import 'package:mosmartpark_desktop/widgets/notification_panel.dart';

class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton>
    with SingleTickerProviderStateMixin {
  final NotificationProvider _notificationProvider = NotificationProvider();
  int _unreadCount = 0;
  Timer? _refreshTimer;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  final OverlayPortalController _overlayController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();

    // Refresh unread count every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadUnreadCount();
    });

    // Pulse animation for unread notifications
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (UserProvider.currentUser == null) return;

    try {
      final count = await _notificationProvider.getUnreadCount(
        UserProvider.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _toggleNotifications() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    } else {
      _overlayController.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _overlayController.hide();
            _loadUnreadCount(); // Refresh count when closing
          },
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Stack(
              children: [
                Positioned(
                  top: 70,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping panel
                      child: const NotificationPanel(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F47).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B6F47).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _toggleNotifications,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _unreadCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_outlined,
                      color: const Color(0xFF8B6F47),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: AnimatedBuilder(
                  animation: _pulseAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation!.value,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
