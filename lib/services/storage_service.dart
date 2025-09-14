// lib/services/storage_service.dart - COMPLETE FIX VERSION
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shared_calculation_data.dart';
import '../models/karyawan_data.dart';
import '../models/menu_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class StorageService {
  // Using constants from AppConstants
  static const String _keySharedData = AppConstants.keySharedData;
  static const String _keyMenuHistory = AppConstants.keyMenuHistory;

  // Maximum history items
  static const int _maxHistoryItems = 20;

  // Auto-save debounce tracker
  static DateTime? _lastAutoSave;

  // Private constructor to prevent instantiation
  StorageService._();

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

      // FIXED: Enhanced JSON serialization with complete null safety
      final jsonData = <String, dynamic>{
        'version': AppConstants.appVersion,
        'variableCosts': _sanitizeVariableCosts(data.variableCosts),
        'fixedCosts': _sanitizeFixedCosts(data.fixedCosts),
        'estimasiPorsi': _ensureFiniteDouble(
            data.estimasiPorsi, AppConstants.defaultEstimasiPorsi),
        'estimasiProduksiBulanan': _ensureFiniteDouble(
            data.estimasiProduksiBulanan, AppConstants.defaultEstimasiProduksi),
        'hppMurniPerPorsi': _ensureFiniteDouble(data.hppMurniPerPorsi, 0.0),
        'biayaVariablePerPorsi':
            _ensureFiniteDouble(data.biayaVariablePerPorsi, 0.0),
        'biayaFixedPerPorsi': _ensureFiniteDouble(data.biayaFixedPerPorsi, 0.0),
        'totalOperationalCost':
            _ensureFiniteDouble(data.totalOperationalCost, 0.0),
        'totalHargaSetelahOperational':
            _ensureFiniteDouble(data.totalHargaSetelahOperational, 0.0),
        'karyawan': _sanitizeKaryawanList(data.karyawan),
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

      if (jsonString == null || jsonString.isEmpty) return null;

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Validate loaded data structure
      if (!_validateLoadedDataStructure(jsonData)) {
        developer.log('Loaded data structure is invalid',
            name: 'StorageService');
        return null;
      }

      // FIXED: Safe parsing of karyawan data with enhanced null safety
      List<KaryawanData> karyawan = <KaryawanData>[];
      if (jsonData['karyawan'] != null && jsonData['karyawan'] is List) {
        try {
          final karyawanList = jsonData['karyawan'] as List<dynamic>;
          for (var item in karyawanList) {
            if (item != null && item is Map<String, dynamic>) {
              try {
                final karyawanItem = KaryawanData.fromMap(item);
                if (karyawanItem.isValid) {
                  karyawan.add(karyawanItem);
                }
              } catch (e) {
                developer.log('Error parsing individual karyawan: $e',
                    name: 'StorageService');
                // Skip invalid karyawan instead of failing completely
              }
            }
          }
        } catch (e) {
          developer.log('Error parsing karyawan list: $e',
              name: 'StorageService');
          // Continue with empty karyawan list
        }
      }

      return SharedCalculationData(
        variableCosts: _parseVariableCosts(jsonData['variableCosts']),
        fixedCosts: _parseFixedCosts(jsonData['fixedCosts']),
        estimasiPorsi: _validateAndClampDouble(
          jsonData['estimasiPorsi'],
          AppConstants.defaultEstimasiPorsi,
          AppConstants.minQuantity,
          AppConstants.maxQuantity,
        ),
        estimasiProduksiBulanan: _validateAndClampDouble(
          jsonData['estimasiProduksiBulanan'],
          AppConstants.defaultEstimasiProduksi,
          AppConstants.minQuantity,
          AppConstants.maxQuantity,
        ),
        hppMurniPerPorsi: _validateAndClampDouble(
            jsonData['hppMurniPerPorsi'], 0.0, 0.0, AppConstants.maxPrice),
        biayaVariablePerPorsi: _validateAndClampDouble(
            jsonData['biayaVariablePerPorsi'], 0.0, 0.0, AppConstants.maxPrice),
        biayaFixedPerPorsi: _validateAndClampDouble(
            jsonData['biayaFixedPerPorsi'], 0.0, 0.0, AppConstants.maxPrice),
        totalOperationalCost: _validateAndClampDouble(
            jsonData['totalOperationalCost'],
            0.0,
            0.0,
            AppConstants.maxPrice * 10),
        totalHargaSetelahOperational: _validateAndClampDouble(
            jsonData['totalHargaSetelahOperational'],
            0.0,
            0.0,
            AppConstants.maxPrice),
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
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? <String>[];

      // Add new menu to beginning of list
      final menuJson = json.encode(menu.toMap());

      // Check if menu already exists (avoid duplicates)
      history.removeWhere((item) {
        try {
          final existing = json.decode(item);
          return existing['nama_menu'] == menu.namaMenu;
        } catch (e) {
          return false; // Keep invalid entries for now
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
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? <String>[];

      List<MenuItem> validMenuItems = <MenuItem>[];

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
      return <MenuItem>[];
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

      // Remove all app-related keys
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

      return <String, dynamic>{
        'sharedDataItems': sharedData?.totalItemCount ?? 0,
        'menuHistoryItems': menuHistory.length,
        'hasData': sharedData != null,
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
      };
    } catch (e) {
      developer.log('Error getting data info: $e', name: 'StorageService');
      return <String, dynamic>{
        'sharedDataItems': 0,
        'menuHistoryItems': 0,
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  // PRIVATE VALIDATION METHODS - COMPLETE NULL SAFETY FIXES

  // Enhanced validation with comprehensive null safety
  static bool _validateSharedData(SharedCalculationData data) {
    try {
      // Validate estimasi porsi
      if (!_isValidDouble(data.estimasiPorsi, AppConstants.minQuantity,
          AppConstants.maxQuantity)) {
        developer.log('Invalid estimasi porsi: ${data.estimasiPorsi}',
            name: 'StorageService');
        return false;
      }

      // Validate estimasi produksi
      if (!_isValidDouble(data.estimasiProduksiBulanan,
          AppConstants.minQuantity, AppConstants.maxQuantity)) {
        developer.log(
            'Invalid estimasi produksi: ${data.estimasiProduksiBulanan}',
            name: 'StorageService');
        return false;
      }

      // Validate karyawan data
      for (var karyawan in data.karyawan) {
        if (!karyawan.isValid) {
          developer.log('Invalid karyawan data: ${karyawan.namaKaryawan}',
              name: 'StorageService');
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Error validating shared data: $e', name: 'StorageService');
      return false;
    }
  }

  // Validate MenuItem using integrated validators
  static bool _validateMenuItem(MenuItem menu) {
    try {
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

        if (!_isValidDouble(komposisi.jumlahDipakai, AppConstants.minQuantity,
            AppConstants.maxQuantity)) {
          developer.log(
              'Invalid ingredient quantity: ${komposisi.jumlahDipakai}',
              name: 'StorageService');
          return false;
        }

        if (!_isValidDouble(komposisi.hargaPerSatuan, AppConstants.minPrice,
            AppConstants.maxPrice)) {
          developer.log('Invalid ingredient price: ${komposisi.hargaPerSatuan}',
              name: 'StorageService');
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Error validating menu item: $e', name: 'StorageService');
      return false;
    }
  }

  // Validate loaded data structure
  static bool _validateLoadedDataStructure(Map<String, dynamic> data) {
    final requiredKeys = <String>[
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

  // FIXED: Enhanced validation and clamping with comprehensive null safety
  static double _validateAndClampDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;

    try {
      double? parsed;
      if (value is double) {
        parsed = value;
      } else if (value is int) {
        parsed = value.toDouble();
      } else if (value is num) {
        parsed = value.toDouble();
      } else if (value is String) {
        if (value.trim().isEmpty) return defaultValue;
        parsed = double.tryParse(value.trim());
      }

      // FIXED: Enhanced null and edge case checks
      if (parsed == null || !parsed.isFinite || parsed.isNaN) {
        return defaultValue;
      }

      // Clamp value within valid range
      return parsed.clamp(min, max);
    } catch (e) {
      developer.log('Error validating double: $value -> $e',
          name: 'StorageService');
      return defaultValue;
    }
  }

  // FIXED: Helper methods for enhanced data sanitization

  static double _ensureFiniteDouble(double value, double defaultValue) {
    return (value.isFinite && !value.isNaN) ? value : defaultValue;
  }

  static bool _isValidDouble(double value, double min, double max) {
    return value.isFinite && !value.isNaN && value >= min && value <= max;
  }

  // FIXED: Enhanced sanitization methods with complete null safety
  static List<Map<String, dynamic>> _sanitizeVariableCosts(
      List<Map<String, dynamic>> costs) {
    return costs.map((cost) {
      return <String, dynamic>{
        'nama': cost['nama']?.toString() ?? '',
        'totalHarga':
            _ensureFiniteDouble(_safeParseDouble(cost['totalHarga']), 0.0),
        'jumlah': _ensureFiniteDouble(_safeParseDouble(cost['jumlah']), 0.0),
        'satuan': cost['satuan']?.toString() ?? 'unit',
        'timestamp':
            cost['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _sanitizeFixedCosts(
      List<Map<String, dynamic>> costs) {
    return costs.map((cost) {
      return <String, dynamic>{
        'jenis': cost['jenis']?.toString() ?? '',
        'nominal': _ensureFiniteDouble(_safeParseDouble(cost['nominal']), 0.0),
        'timestamp':
            cost['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _sanitizeKaryawanList(
      List<KaryawanData> karyawan) {
    return karyawan.where((k) => k.isValid).map((k) => k.toMap()).toList();
  }

  // FIXED: Removed unnecessary cast - This fixes the warning!
  static List<Map<String, dynamic>> _parseVariableCosts(dynamic data) {
    if (data == null || data is! List) return <Map<String, dynamic>>[];
    try {
      // FIXED: Direct cast without unnecessary intermediate cast
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('Error parsing variable costs: $e', name: 'StorageService');
      return <Map<String, dynamic>>[];
    }
  }

  // FIXED: Removed unnecessary cast - This fixes the warning!
  static List<Map<String, dynamic>> _parseFixedCosts(dynamic data) {
    if (data == null || data is! List) return <Map<String, dynamic>>[];
    try {
      // FIXED: Direct cast without unnecessary intermediate cast
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('Error parsing fixed costs: $e', name: 'StorageService');
      return <Map<String, dynamic>>[];
    }
  }

  // FIXED: New helper method for safe double parsing
  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return 0.0;
        return double.tryParse(trimmed) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      developer.log('Error parsing double from: $value',
          name: 'StorageService');
      return 0.0;
    }
  }
}
