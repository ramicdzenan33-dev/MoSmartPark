import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mosmartpark_mobile/providers/settings_provider.dart';
import 'package:mosmartpark_mobile/providers/parking_zone_provider.dart';
import 'package:mosmartpark_mobile/providers/user_provider.dart';
import 'package:mosmartpark_mobile/model/parking_zone.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<ParkingZone> _parkingZones = [];
  bool _isLoadingZones = true;

  int get _userId => UserProvider.currentUser?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParkingZones();
      final settings = context.read<SettingsProvider>();
      if (settings.preferences == null && _userId != 0) {
        settings.loadPreferences(_userId);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadParkingZones() async {
    try {
      final provider = context.read<ParkingZoneProvider>();
      final result = await provider.get(filter: {'retrieveAll': true});
      if (mounted) {
        setState(() {
          _parkingZones =
              (result.items ?? []).where((z) => z.isActive).toList();
          _isLoadingZones = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingZones = false);
      }
    }
  }

  bool get _isAdmin {
    final user = UserProvider.currentUser;
    if (user == null) return false;
    return user.roles
        .any((role) => role.id == 1 || role.name.toLowerCase() == 'admin');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (settings.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF8B6F47),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Customize how the app looks',
            ),
            const SizedBox(height: 12),
            _buildThemeCard(context, settings, isDark),
            const SizedBox(height: 28),
            _buildSectionHeader(
              context,
              icon: Icons.local_parking_rounded,
              title: 'Parking Preferences',
              subtitle: 'Set your default parking zone',
            ),
            const SizedBox(height: 12),
            _buildParkingZoneCard(context, settings, isDark),
            if (_isAdmin) ...[
              const SizedBox(height: 28),
              _buildSectionHeader(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notification Preferences',
                subtitle: 'Choose which notifications you receive',
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(context, settings, isDark),
            ],
            const SizedBox(height: 28),
            _buildResetButton(context, settings, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B6F47), Color(0xFFA0826D)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B6F47).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ThemeModeOption(
              icon: Icons.brightness_auto_rounded,
              title: 'System Default',
              subtitle: 'Follow your device settings',
              isSelected: settings.themeMode == ThemeMode.system,
              onTap: () => settings.setThemeMode(ThemeMode.system, _userId),
              isDark: isDark,
            ),
            Divider(
              height: 1,
              color:
                  isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
            ),
            _ThemeModeOption(
              icon: Icons.light_mode_rounded,
              title: 'Light Mode',
              subtitle: 'Classic bright appearance',
              isSelected: settings.themeMode == ThemeMode.light,
              onTap: () => settings.setThemeMode(ThemeMode.light, _userId),
              isDark: isDark,
            ),
            Divider(
              height: 1,
              color:
                  isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
            ),
            _ThemeModeOption(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Easy on the eyes at night',
              isSelected: settings.themeMode == ThemeMode.dark,
              onTap: () => settings.setThemeMode(ThemeMode.dark, _userId),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingZoneCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: const Color(0xFF8B6F47),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Default Parking Zone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Auto-filter reservations to your preferred zone when creating a new booking.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingZones)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: settings.defaultParkingZoneId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8B6F47),
                    ),
                    hint: Text(
                      'Select a parking zone',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'No default (show all)',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._parkingZones.map(
                        (zone) => DropdownMenuItem<int?>(
                          value: zone.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B6F47),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                zone.name,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      final zoneName = value != null
                          ? _parkingZones
                              .firstWhere((z) => z.id == value)
                              .name
                          : null;
                      settings.setDefaultParkingZone(
                          value, zoneName, _userId);
                    },
                  ),
                ),
              ),
            if (settings.defaultParkingZoneName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F47).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B6F47).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8B6F47),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New reservations will default to "${settings.defaultParkingZoneName}"',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B6F47),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
              onChanged: (v) => settings.setNotifyReviews(v, _userId),
              isDark: isDark,
              color: const Color(0xFF8B5CF6),
            ),
            Divider(
              height: 24,
              color:
                  isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
            ),
            _NotificationToggle(
              icon: Icons.calendar_month_rounded,
              title: 'Reservations',
              subtitle: 'When new parking reservations are made',
              value: settings.notifyReservations,
              onChanged: (v) => settings.setNotifyReservations(v, _userId),
              isDark: isDark,
              color: const Color(0xFF3B82F6),
            ),
            Divider(
              height: 24,
              color:
                  isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
            ),
            _NotificationToggle(
              icon: Icons.directions_car_outlined,
              title: 'Cars',
              subtitle: 'When cars are registered or updated',
              value: settings.notifyCars,
              onChanged: (v) => settings.setNotifyCars(v, _userId),
              isDark: isDark,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showResetConfirmation(context, settings),
        icon: Icon(
          Icons.restart_alt_rounded,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        label: Text(
          'Reset All Preferences',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 10),
            Text(
              'Reset Preferences',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          'This will restore all settings to their default values. Are you sure?',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetAllPreferences(_userId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Preferences reset to defaults'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF8B6F47),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6F47),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B6F47).withOpacity(0.15)
                    : isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF8B6F47)
                    : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF8B6F47)
                          : isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF8B6F47)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B6F47)
                      : isDark
                          ? Colors.grey[600]!
                          : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
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
  final bool isDark;
  final Color color;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8B6F47),
          activeTrackColor: const Color(0xFF8B6F47).withOpacity(0.3),
        ),
      ],
    );
  }
}
