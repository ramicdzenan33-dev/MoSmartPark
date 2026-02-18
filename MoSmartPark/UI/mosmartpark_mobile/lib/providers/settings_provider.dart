import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mosmartpark_mobile/model/user_preferences.dart';
import 'package:mosmartpark_mobile/providers/auth_provider.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class SettingsProvider with ChangeNotifier {
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ThemeMode get themeMode {
    switch (_preferences?.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int? get defaultParkingZoneId => _preferences?.defaultParkingZoneId;
  String? get defaultParkingZoneName => _preferences?.defaultParkingZoneName;
  bool get notifyReviews => _preferences?.notifyReviews ?? true;
  bool get notifyReservations => _preferences?.notifyReservations ?? true;
  bool get notifyCars => _preferences?.notifyCars ?? true;

  Map<String, String> _createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";
    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };
  }

  Future<void> loadPreferences(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var url = "${BaseProvider.baseUrl}UserPreferences/user/$userId";
      var response = await http.get(Uri.parse(url), headers: _createHeaders());

      if (response.statusCode < 300) {
        var data = jsonDecode(response.body);
        _preferences = UserPreferences.fromJson(data);
      } else {
        _error = "Failed to load preferences";
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _savePreferences(int userId) async {
    try {
      var url = "${BaseProvider.baseUrl}UserPreferences/user/$userId";
      var body = jsonEncode({
        "userId": userId,
        "themeMode": _preferences?.themeMode ?? "system",
        "defaultParkingZoneId": _preferences?.defaultParkingZoneId,
        "notifyReviews": _preferences?.notifyReviews ?? true,
        "notifyReservations": _preferences?.notifyReservations ?? true,
        "notifyCars": _preferences?.notifyCars ?? true,
      });

      var response = await http.put(
        Uri.parse(url),
        headers: _createHeaders(),
        body: body,
      );

      if (response.statusCode < 300) {
        var data = jsonDecode(response.body);
        _preferences = UserPreferences.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode, int userId) async {
    String themeModeStr;
    switch (mode) {
      case ThemeMode.light:
        themeModeStr = 'light';
      case ThemeMode.dark:
        themeModeStr = 'dark';
      default:
        themeModeStr = 'system';
    }

    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: themeModeStr,
      defaultParkingZoneId: _preferences?.defaultParkingZoneId,
      defaultParkingZoneName: _preferences?.defaultParkingZoneName,
      notifyReviews: _preferences?.notifyReviews ?? true,
      notifyReservations: _preferences?.notifyReservations ?? true,
      notifyCars: _preferences?.notifyCars ?? true,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  Future<void> setDefaultParkingZone(
      int? zoneId, String? zoneName, int userId) async {
    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: _preferences?.themeMode ?? 'system',
      defaultParkingZoneId: zoneId,
      defaultParkingZoneName: zoneName,
      notifyReviews: _preferences?.notifyReviews ?? true,
      notifyReservations: _preferences?.notifyReservations ?? true,
      notifyCars: _preferences?.notifyCars ?? true,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  Future<void> setNotifyReviews(bool value, int userId) async {
    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: _preferences?.themeMode ?? 'system',
      defaultParkingZoneId: _preferences?.defaultParkingZoneId,
      defaultParkingZoneName: _preferences?.defaultParkingZoneName,
      notifyReviews: value,
      notifyReservations: _preferences?.notifyReservations ?? true,
      notifyCars: _preferences?.notifyCars ?? true,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  Future<void> setNotifyReservations(bool value, int userId) async {
    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: _preferences?.themeMode ?? 'system',
      defaultParkingZoneId: _preferences?.defaultParkingZoneId,
      defaultParkingZoneName: _preferences?.defaultParkingZoneName,
      notifyReviews: _preferences?.notifyReviews ?? true,
      notifyReservations: value,
      notifyCars: _preferences?.notifyCars ?? true,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  Future<void> setNotifyCars(bool value, int userId) async {
    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: _preferences?.themeMode ?? 'system',
      defaultParkingZoneId: _preferences?.defaultParkingZoneId,
      defaultParkingZoneName: _preferences?.defaultParkingZoneName,
      notifyReviews: _preferences?.notifyReviews ?? true,
      notifyReservations: _preferences?.notifyReservations ?? true,
      notifyCars: value,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  Future<void> resetAllPreferences(int userId) async {
    _preferences = UserPreferences(
      id: _preferences?.id ?? 0,
      userId: userId,
      themeMode: 'system',
      defaultParkingZoneId: null,
      defaultParkingZoneName: null,
      notifyReviews: true,
      notifyReservations: true,
      notifyCars: true,
    );
    notifyListeners();
    await _savePreferences(userId);
  }

  void clear() {
    _preferences = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
