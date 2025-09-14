// lib/services/storage_service.dart - CLEANED VERSION: NO EXPORT/IMPORT
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shared_calculation_data.dart';
import '../models/karyawan_data.dart';
import '../models/menu_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class StorageService {
  // Using constants from AppConstants instead of local constants
  static const String _keySharedData = AppConstants.keySharedData;
  static const String _keyMenuHistory = AppConstants.keyMenuHistory;

  // Maximum history items using validation approach
  static const int _maxHistoryItems = 20;

  // Auto-save debounce tracker
  static DateTime? _lastAutoSave;

  // Save shared calculation data with comprehensive validation
  static Future<bool> saveSharedData(SharedCalculationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Validate data before saving
      if (!_validateSharedData(data)) {
        developer.log('Data validation failed during save',
            name: 'StorageService');
        return false;
      }

      final jsonData = {
        'version': AppConstants.appVersion, // Using constant
        'variableCosts': data.variableCosts,
        'fixedCosts': data.fixedCosts,
        'estimasiPorsi': data.estimasiPorsi,
        'estimasiProduksiBulanan': data.estimasiProduksiBulanan,
        'karyawan': data.karyawan.map((k) => k.toMap()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final jsonString = json.encode(jsonData);

      // Check data size against reasonable limits
      if (jsonString.length > 1024 * 1024) {
        // 1MB limit
        developer.log('Data size too large: ${jsonString.length} bytes',
            name: 'StorageService');
        return false;
      }

      return await prefs.setString(_keySharedData, jsonString);
    } catch (e) {
      developer.log('Error saving data: $e', name: 'StorageService');
      return false;
    }
  }

  // Load shared calculation data with validation
  static Future<SharedCalculationData?> loadSharedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keySharedData);

      if (jsonString == null) return null;

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Validate loaded data structure
      if (!_validateLoadedDataStructure(jsonData)) {
        developer.log('Loaded data structure is invalid',
            name: 'StorageService');
        return null;
      }

      List<KaryawanData> karyawan = [];
      if (jsonData['karyawan'] != null) {
        try {
          karyawan = (jsonData['karyawan'] as List)
              .map((item) => KaryawanData.fromMap(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          developer.log('Error parsing karyawan data: $e',
              name: 'StorageService');
          // Continue with empty karyawan list instead of failing completely
        }
      }

      // Use constants for default values
      final estimasiPorsi = _validateAndClampDouble(
        jsonData['estimasiPorsi'],
        AppConstants.defaultEstimasiPorsi,
        AppConstants.minQuantity,
        AppConstants.maxQuantity,
      );

      final estimasiProduksi = _validateAndClampDouble(
        jsonData['estimasiProduksiBulanan'],
        AppConstants.defaultEstimasiProduksi,
        AppConstants.minQuantity,
        AppConstants.maxQuantity,
      );

      return SharedCalculationData(
        variableCosts:
            List<Map<String, dynamic>>.from(jsonData['variableCosts'] ?? []),
        fixedCosts:
            List<Map<String, dynamic>>.from(jsonData['fixedCosts'] ?? []),
        estimasiPorsi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksi,
        karyawan: karyawan,
      );
    } catch (e) {
      developer.log('Error loading data: $e', name: 'StorageService');
      return null;
    }
  }

  // Save menu to history with validation
  static Future<bool> saveMenuToHistory(MenuItem menu) async {
    try {
      // Validate menu data before saving
      if (!_validateMenuItem(menu)) {
        developer.log('Menu validation failed', name: 'StorageService');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      // Add new menu to beginning of list
      final menuJson = json.encode(menu.toMap());

      // Check if menu already exists (avoid duplicates)
      history.removeWhere((item) {
        try {
          final existing = json.decode(item);
          return existing['nama_menu'] == menu.namaMenu;
        } catch (e) {
          return false;
        }
      });

      history.insert(0, menuJson);

      // Keep only specified number of recent menus
      if (history.length > _maxHistoryItems) {
        history = history.take(_maxHistoryItems).toList();
      }

      return await prefs.setStringList(_keyMenuHistory, history);
    } catch (e) {
      developer.log('Error saving menu history: $e', name: 'StorageService');
      return false;
    }
  }

  // Load menu history with validation
  static Future<List<MenuItem>> loadMenuHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      List<MenuItem> validMenuItems = [];

      for (String jsonString in history) {
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          final menuItem = MenuItem.fromMap(jsonData);

          // Validate loaded menu item
          if (_validateMenuItem(menuItem)) {
            validMenuItems.add(menuItem);
          } else {
            developer.log('Skipping invalid menu item: ${menuItem.namaMenu}',
                name: 'StorageService');
          }
        } catch (e) {
          developer.log('Error parsing menu item: $e', name: 'StorageService');
          // Skip invalid items instead of failing completely
        }
      }

      return validMenuItems;
    } catch (e) {
      developer.log('Error loading menu history: $e', name: 'StorageService');
      return [];
    }
  }

  // Auto-save with debounce functionality
  static Future<void> autoSave(SharedCalculationData data) async {
    final now = DateTime.now();

    // Implement debounce using constants
    if (_lastAutoSave != null &&
        now.difference(_lastAutoSave!).inMilliseconds <
            AppConstants.debounceDuration.inMilliseconds) {
      return;
    }

    _lastAutoSave = now;

    // Save data
    final success = await saveSharedData(data);
    if (success) {
      developer.log('Auto-save completed', name: 'StorageService');
    } else {
      developer.log('Auto-save failed', name: 'StorageService');
    }
  }

  // Clear all data with confirmation
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove all app-related keys (removed backup key)
      final keys = [_keySharedData, _keyMenuHistory];

      bool success = true;
      for (String key in keys) {
        final removed = await prefs.remove(key);
        if (!removed) {
          developer.log('Failed to remove key: $key', name: 'StorageService');
          success = false;
        }
      }

      if (success) {
        developer.log('All data cleared successfully', name: 'StorageService');
      }

      return success;
    } catch (e) {
      developer.log('Error clearing data: $e', name: 'StorageService');
      return false;
    }
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

  // Get data size with detailed breakdown
  static Future<Map<String, dynamic>> getDataInfo() async {
    try {
      final sharedData = await loadSharedData();
      final menuHistory = await loadMenuHistory();

      return {
        'sharedDataItems': sharedData?.totalItemCount ?? 0,
        'menuHistoryItems': menuHistory.length,
        'hasData': sharedData != null,
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
      };
    } catch (e) {
      developer.log('Error getting data info: $e', name: 'StorageService');
      return {
        'sharedDataItems': 0,
        'menuHistoryItems': 0,
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  // PRIVATE VALIDATION METHODS

  // Validate SharedCalculationData using integrated validators
  static bool _validateSharedData(SharedCalculationData data) {
    // Validate estimasi porsi
    final porsiValidation =
        InputValidator.validateQuantity(data.estimasiPorsi.toString());
    if (porsiValidation != null) {
      developer.log('Invalid estimasi porsi: $porsiValidation',
          name: 'StorageService');
      return false;
    }

    // Validate estimasi produksi
    final produksiValidation = InputValidator.validateQuantity(
        data.estimasiProduksiBulanan.toString());
    if (produksiValidation != null) {
      developer.log('Invalid estimasi produksi: $produksiValidation',
          name: 'StorageService');
      return false;
    }

    // Validate karyawan data
    for (var karyawan in data.karyawan) {
      final namaValidation = InputValidator.validateName(karyawan.namaKaryawan);
      if (namaValidation != null) {
        developer.log('Invalid karyawan name: $namaValidation',
            name: 'StorageService');
        return false;
      }

      final salaryValidation =
          InputValidator.validateSalary(karyawan.gajiBulanan.toString());
      if (salaryValidation != null) {
        developer.log(
            'Invalid salary for ${karyawan.namaKaryawan}: $salaryValidation',
            name: 'StorageService');
        return false;
      }
    }

    return true;
  }

  // Validate MenuItem using integrated validators
  static bool _validateMenuItem(MenuItem menu) {
    final nameValidation = InputValidator.validateName(menu.namaMenu);
    if (nameValidation != null) {
      developer.log('Invalid menu name: $nameValidation',
          name: 'StorageService');
      return false;
    }

    // Validate menu compositions
    for (var komposisi in menu.komposisi) {
      final ingredientValidation =
          InputValidator.validateName(komposisi.namaIngredient);
      if (ingredientValidation != null) {
        developer.log('Invalid ingredient name: $ingredientValidation',
            name: 'StorageService');
        return false;
      }

      final quantityValidation =
          InputValidator.validateQuantity(komposisi.jumlahDipakai.toString());
      if (quantityValidation != null) {
        developer.log('Invalid ingredient quantity: $quantityValidation',
            name: 'StorageService');
        return false;
      }

      final priceValidation =
          InputValidator.validatePrice(komposisi.hargaPerSatuan.toString());
      if (priceValidation != null) {
        developer.log('Invalid ingredient price: $priceValidation',
            name: 'StorageService');
        return false;
      }
    }

    return true;
  }

  // Validate loaded data structure
  static bool _validateLoadedDataStructure(Map<String, dynamic> data) {
    final requiredKeys = [
      'variableCosts',
      'fixedCosts',
      'estimasiPorsi',
      'estimasiProduksiBulanan'
    ];

    for (String key in requiredKeys) {
      if (!data.containsKey(key)) {
        developer.log('Missing required key: $key', name: 'StorageService');
        return false;
      }
    }

    return true;
  }

  // Validate and clamp double values using constants
  static double _validateAndClampDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;

    double? parsed =
        value is double ? value : double.tryParse(value.toString());
    if (parsed == null) return defaultValue;

    // Clamp value within valid range
    return parsed.clamp(min, max);
  }
}
