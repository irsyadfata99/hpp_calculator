// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shared_calculation_data.dart';
import '../models/karyawan_data.dart';
import '../models/menu_model.dart';

class StorageService {
  static const String _keySharedData = 'shared_calculation_data';
  static const String _keyMenuHistory = 'menu_history';
  static const String _keyBackupData = 'backup_data';

  // Save shared calculation data
  static Future<bool> saveSharedData(SharedCalculationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = {
        'variableCosts': data.variableCosts,
        'fixedCosts': data.fixedCosts,
        'estimasiPorsi': data.estimasiPorsi,
        'estimasiProduksiBulanan': data.estimasiProduksiBulanan,
        'karyawan': data.karyawan.map((k) => k.toMap()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      return await prefs.setString(_keySharedData, json.encode(jsonData));
    } catch (e) {
      developer.log('Error saving data: $e', name: 'StorageService');
      return false;
    }
  }

  // Load shared calculation data
  static Future<SharedCalculationData?> loadSharedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keySharedData);

      if (jsonString == null) return null;

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<KaryawanData> karyawan = (jsonData['karyawan'] as List)
          .map((item) => KaryawanData.fromMap(item))
          .toList();

      return SharedCalculationData(
        variableCosts:
            List<Map<String, dynamic>>.from(jsonData['variableCosts'] ?? []),
        fixedCosts:
            List<Map<String, dynamic>>.from(jsonData['fixedCosts'] ?? []),
        estimasiPorsi: jsonData['estimasiPorsi']?.toDouble() ?? 1.0,
        estimasiProduksiBulanan:
            jsonData['estimasiProduksiBulanan']?.toDouble() ?? 30.0,
        karyawan: karyawan,
      );
    } catch (e) {
      developer.log('Error loading data: $e', name: 'StorageService');
      return null;
    }
  }

  // Save menu to history
  static Future<bool> saveMenuToHistory(MenuItem menu) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      // Add new menu to beginning of list
      history.insert(0, json.encode(menu.toMap()));

      // Keep only last 20 menus
      if (history.length > 20) {
        history = history.take(20).toList();
      }

      return await prefs.setStringList(_keyMenuHistory, history);
    } catch (e) {
      developer.log('Error saving menu history: $e', name: 'StorageService');
      return false;
    }
  }

  // Load menu history
  static Future<List<MenuItem>> loadMenuHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      return history.map((jsonString) {
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        return MenuItem.fromMap(jsonData);
      }).toList();
    } catch (e) {
      developer.log('Error loading menu history: $e', name: 'StorageService');
      return [];
    }
  }

  // Export data for backup
  static Future<String?> exportData() async {
    try {
      final sharedData = await loadSharedData();
      final menuHistory = await loadMenuHistory();

      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'sharedData': sharedData?.toMap(),
        'menuHistory': menuHistory.map((m) => m.toMap()).toList(),
      };

      return json.encode(exportData);
    } catch (e) {
      developer.log('Error exporting data: $e', name: 'StorageService');
      return null;
    }
  }

  // Import data from backup
  static Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);

      // Validate import data structure
      if (!importData.containsKey('version') ||
          !importData.containsKey('sharedData')) {
        throw Exception('Invalid backup file format');
      }

      // Import shared data
      if (importData['sharedData'] != null) {
        final sharedDataMap = importData['sharedData'] as Map<String, dynamic>;

        // Create SharedCalculationData from imported data
        List<KaryawanData> karyawan = (sharedDataMap['karyawan'] as List?)
                ?.map((item) => KaryawanData.fromMap(item))
                .toList() ??
            [];

        final sharedData = SharedCalculationData(
          variableCosts: List<Map<String, dynamic>>.from(
              sharedDataMap['variableCosts'] ?? []),
          fixedCosts: List<Map<String, dynamic>>.from(
              sharedDataMap['fixedCosts'] ?? []),
          estimasiPorsi: sharedDataMap['estimasiPorsi']?.toDouble() ?? 1.0,
          estimasiProduksiBulanan:
              sharedDataMap['estimasiProduksiBulanan']?.toDouble() ?? 30.0,
          karyawan: karyawan,
        );

        await saveSharedData(sharedData);
      }

      // Import menu history
      if (importData['menuHistory'] != null) {
        final prefs = await SharedPreferences.getInstance();
        List<String> history = (importData['menuHistory'] as List)
            .map((item) => json.encode(item))
            .toList();
        await prefs.setStringList(_keyMenuHistory, history);
      }

      return true;
    } catch (e) {
      developer.log('Error importing data: $e', name: 'StorageService');
      return false;
    }
  }

  // Clear all data
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySharedData);
      await prefs.remove(_keyMenuHistory);
      await prefs.remove(_keyBackupData);
      return true;
    } catch (e) {
      developer.log('Error clearing data: $e', name: 'StorageService');
      return false;
    }
  }

  // Auto-save functionality
  static Future<void> autoSave(SharedCalculationData data) async {
    // Save data every 30 seconds or when significant changes occur
    await saveSharedData(data);
  }

  // Check if data exists
  static Future<bool> hasStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keySharedData);
    } catch (e) {
      developer.log('Error checking stored data: $e', name: 'StorageService');
      return false;
    }
  }

  // Get data size (for debugging/info purposes)
  static Future<int> getDataSize() async {
    try {
      final dataString = await exportData();
      return dataString?.length ?? 0;
    } catch (e) {
      developer.log('Error getting data size: $e', name: 'StorageService');
      return 0;
    }
  }
}
