import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider with ChangeNotifier {
  static const String _quickModeKey = 'quick_mode_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';

  bool _isQuickMode = false;
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  // FIXED: Use consistent naming with main.dart
  bool get isQuickMode => _isQuickMode;
  bool get isDarkMode => _isDarkMode;

  // FIXED: Method name to match main.dart call
  Future<void> initializeSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isQuickMode = _prefs?.getBool(_quickModeKey) ?? false;
      _isDarkMode = _prefs?.getBool(_darkModeKey) ?? false;
      notifyListeners();
      debugPrint(
          'AppSettings initialized - Quick Mode: $_isQuickMode, Dark Mode: $_isDarkMode');
    } catch (e) {
      debugPrint('Error initializing AppSettings: $e');
    }
  }

  Future<void> toggleQuickMode() async {
    try {
      _isQuickMode = !_isQuickMode;
      await _prefs?.setBool(_quickModeKey, _isQuickMode);
      notifyListeners();
      debugPrint('Quick Mode toggled: $_isQuickMode');
    } catch (e) {
      debugPrint('Error toggling quick mode: $e');
    }
  }

  Future<void> setQuickMode(bool enabled) async {
    try {
      if (_isQuickMode != enabled) {
        _isQuickMode = enabled;
        await _prefs?.setBool(_quickModeKey, enabled);
        notifyListeners();
        debugPrint('Quick Mode set to: $enabled');
      }
    } catch (e) {
      debugPrint('Error setting quick mode: $e');
    }
  }

  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      await _prefs?.setBool(_darkModeKey, _isDarkMode);
      notifyListeners();
      debugPrint('Dark Mode toggled: $_isDarkMode');
    } catch (e) {
      debugPrint('Error toggling dark mode: $e');
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    try {
      if (_isDarkMode != enabled) {
        _isDarkMode = enabled;
        await _prefs?.setBool(_darkModeKey, enabled);
        notifyListeners();
        debugPrint('Dark Mode set to: $enabled');
      }
    } catch (e) {
      debugPrint('Error setting dark mode: $e');
    }
  }
}
