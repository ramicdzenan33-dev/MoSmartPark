import 'package:flutter/material.dart';
import 'package:mosmartpark_desktop/layouts/master_screen.dart';
import 'package:mosmartpark_desktop/providers/settings_provider.dart';
import 'package:mosmartpark_desktop/providers/user_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int get _userId => UserProvider.currentUser?.id ?? 0;

  Future<void> _onToggle(BuildContext context, Future<bool> Function() save) async {
    final ok = await save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Preferences saved. Notifications updated.' : 'Failed to save. Please try again.'),
        backgroundColor: ok ? null : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userId != 0) {
        context.read<SettingsProvider>().loadPreferences(_userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MasterScreen(
      title: 'Settings',
      child: settings.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B6F47),
              ),
            )
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.notifications_outlined,
                      title: 'Notification Preferences',
                      subtitle:
                          'Choose which notifications you receive in the app.',
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationCard(context, settings),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B6F47).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF8B6F47)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _NotificationToggle(
              icon: Icons.rate_review_outlined,
              title: 'Reviews',
              subtitle: 'When users submit new reviews',
              value: settings.notifyReviews,
              onChanged: (v) => _onToggle(context, () => settings.setNotifyReviews(v, _userId)),
              color: const Color(0xFF8B5CF6),
            ),
            Divider(
              height: 24,
              color: Colors.grey[200],
            ),
            _NotificationToggle(
              icon: Icons.calendar_month_rounded,
              title: 'Reservations',
              subtitle: 'When new parking reservations are made',
              value: settings.notifyReservations,
              onChanged: (v) => _onToggle(context, () => settings.setNotifyReservations(v, _userId)),
              color: const Color(0xFF3B82F6),
            ),
            Divider(
              height: 24,
              color: Colors.grey[200],
            ),
            _NotificationToggle(
              icon: Icons.directions_car_outlined,
              title: 'Cars',
              subtitle: 'When cars are registered or updated',
              value: settings.notifyCars,
              onChanged: (v) => _onToggle(context, () => settings.setNotifyCars(v, _userId)),
              color: const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Theme(
          data: Theme.of(context).copyWith(
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF8B6F47);
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF8B6F47).withOpacity(0.3);
                }
                return null;
              }),
            ),
          ),
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
