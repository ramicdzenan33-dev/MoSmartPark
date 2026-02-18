import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mosmartpark_desktop/model/user_preferences.dart';
import 'package:mosmartpark_desktop/providers/auth_provider.dart';
import 'package:mosmartpark_desktop/providers/base_provider.dart';

class SettingsProvider with ChangeNotifier {
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get notifyReviews => _preferences?.notifyReviews ?? true;
  bool get notifyReservations => _preferences?.notifyReservations ?? true;
  bool get notifyCars => _preferences?.notifyCars ?? true;

  Map<String, String> _createHeaders() {
    final username = AuthProvider.username ?? '';
    final password = AuthProvider.password ?? '';
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  Future<void> loadPreferences(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = '${BaseProvider.baseUrl}UserPreferences/user/$userId';
      final response = await http.get(Uri.parse(url), headers: _createHeaders());

      if (response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _preferences = UserPreferences.fromJson(data);
      } else {
        _error = 'Failed to load preferences';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Returns true if save succeeded, false otherwise. On failure, [ _error ] is set.
  Future<bool> _savePreferences(int userId) async {
    try {
      final url = '${BaseProvider.baseUrl}UserPreferences/user/$userId';
      final body = jsonEncode({
        'userId': userId,
        'themeMode': _preferences?.themeMode ?? 'system',
        'defaultParkingZoneId': _preferences?.defaultParkingZoneId,
        'notifyReviews': _preferences?.notifyReviews ?? true,
        'notifyReservations': _preferences?.notifyReservations ?? true,
        'notifyCars': _preferences?.notifyCars ?? true,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: _createHeaders(),
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _preferences = UserPreferences.fromJson(data);
        _error = null;
        notifyListeners();
        return true;
      }
      _error = 'Failed to save preferences (${response.statusCode})';
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
    return false;
  }

  Future<bool> setNotifyReviews(bool value, int userId) async {
    final previous = _preferences;
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
    final ok = await _savePreferences(userId);
    if (!ok && previous != null) {
      _preferences = previous;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> setNotifyReservations(bool value, int userId) async {
    final previous = _preferences;
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
    final ok = await _savePreferences(userId);
    if (!ok && previous != null) {
      _preferences = previous;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> setNotifyCars(bool value, int userId) async {
    final previous = _preferences;
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
    final ok = await _savePreferences(userId);
    if (!ok && previous != null) {
      _preferences = previous;
      notifyListeners();
    }
    return ok;
  }

  void clear() {
    _preferences = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
