// lib/services/storage_service.dart - PHASE 1.5 FIX: Data Persistence
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shared_calculation_data.dart';
import '../models/karyawan_data.dart';
import '../models/menu_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class StorageService {
  // FIXED: Separate storage keys to prevent conflicts
  static const String _keySharedData = 'hpp_shared_data_v2';
  static const String _keyMenuHistory = 'menu_history_v2';
  static const String _keyKaryawanData = 'karyawan_data_v2';

  // Auto-save coordination
  static DateTime? _lastAutoSave;
  static bool _isSaving = false;

  // Private constructor
  StorageService._();

  // FIXED: Coordinated save to prevent conflicts
  static Future<bool> saveSharedData(SharedCalculationData data) async {
    if (_isSaving) {
      developer.log('Save in progress, skipping...', name: 'StorageService');
      return false;
    }

    _isSaving = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // FIXED: Enhanced JSON serialization with type safety
      final jsonData = <String, dynamic>{
        'version': AppConstants.appVersion,
        'timestamp': DateTime.now().toIso8601String(),

        // HPP Data
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

        // Operational Data
        'totalOperationalCost':
            _ensureFiniteDouble(data.totalOperationalCost, 0.0),
        'totalHargaSetelahOperational':
            _ensureFiniteDouble(data.totalHargaSetelahOperational, 0.0),
      };

      final jsonString = json.encode(jsonData);

      // Save shared data
      final sharedResult = await prefs.setString(_keySharedData, jsonString);

      // FIXED: Save karyawan data separately to prevent conflicts
      final karyawanResult = await _saveKaryawanData(data.karyawan);

      developer.log(
          'SharedData saved: $sharedResult, Karyawan saved: $karyawanResult',
          name: 'StorageService');

      return sharedResult && karyawanResult;
    } catch (e) {
      developer.log('Error saving data: $e', name: 'StorageService');
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // FIXED: Enhanced load with separate data sources
  static Future<SharedCalculationData?> loadSharedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load shared data
      final String? sharedJsonString = prefs.getString(_keySharedData);
      if (sharedJsonString == null || sharedJsonString.isEmpty) {
        developer.log('No shared data found', name: 'StorageService');
        return null;
      }

      final Map<String, dynamic> jsonData = json.decode(sharedJsonString);

      // FIXED: Load karyawan data separately
      final List<KaryawanData> karyawan = await _loadKaryawanData();

      final sharedData = SharedCalculationData(
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

      developer.log(
          'Data loaded: ${sharedData.totalItemCount} items, ${karyawan.length} karyawan',
          name: 'StorageService');
      return sharedData;
    } catch (e) {
      developer.log('Error loading data: $e', name: 'StorageService');
      return null;
    }
  }

  // FIXED: Separate karyawan data management
  static Future<bool> _saveKaryawanData(List<KaryawanData> karyawan) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final validKaryawan = karyawan.where((k) => k.isValid).toList();
      final karyawanJson = validKaryawan.map((k) => k.toMap()).toList();

      final karyawanString = json.encode({
        'version': AppConstants.appVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'karyawan': karyawanJson,
      });

      return await prefs.setString(_keyKaryawanData, karyawanString);
    } catch (e) {
      developer.log('Error saving karyawan: $e', name: 'StorageService');
      return false;
    }
  }

  static Future<List<KaryawanData>> _loadKaryawanData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? karyawanString = prefs.getString(_keyKaryawanData);

      if (karyawanString == null || karyawanString.isEmpty) {
        return [];
      }

      final Map<String, dynamic> karyawanData = json.decode(karyawanString);
      final List<dynamic> karyawanList = karyawanData['karyawan'] ?? [];

      List<KaryawanData> validKaryawan = [];

      for (var item in karyawanList) {
        try {
          if (item is Map<String, dynamic>) {
            final karyawan = KaryawanData.fromMap(item);
            if (karyawan.isValid) {
              validKaryawan.add(karyawan);
            }
          }
        } catch (e) {
          developer.log('Skipping invalid karyawan: $e',
              name: 'StorageService');
        }
      }

      return validKaryawan;
    } catch (e) {
      developer.log('Error loading karyawan: $e', name: 'StorageService');
      return [];
    }
  }

  // FIXED: Enhanced menu history management
  static Future<bool> saveMenuToHistory(MenuItem menu) async {
    try {
      if (!_validateMenuItem(menu)) {
        developer.log('Menu validation failed', name: 'StorageService');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      // Create menu data with validation
      final menuData = {
        'id': menu.id,
        'nama_menu': menu.namaMenu,
        'komposisi': menu.komposisi
            .map((item) => {
                  'nama_ingredient': item.namaIngredient,
                  'jumlah_dipakai':
                      _ensureFiniteDouble(item.jumlahDipakai, 0.0),
                  'satuan': item.satuan,
                  'harga_per_satuan':
                      _ensureFiniteDouble(item.hargaPerSatuan, 0.0),
                })
            .toList(),
        'created_at': menu.createdAt.toIso8601String(),
        'version': AppConstants.appVersion,
      };

      final menuJson = json.encode(menuData);

      // Remove duplicates
      history.removeWhere((item) {
        try {
          final existing = json.decode(item);
          return existing['nama_menu'] == menu.namaMenu;
        } catch (e) {
          return false;
        }
      });

      history.insert(0, menuJson);

      // Keep only recent menus
      if (history.length > 20) {
        history = history.take(20).toList();
      }

      return await prefs.setStringList(_keyMenuHistory, history);
    } catch (e) {
      developer.log('Error saving menu history: $e', name: 'StorageService');
      return false;
    }
  }

  static Future<List<MenuItem>> loadMenuHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      List<MenuItem> validMenuItems = [];

      for (String jsonString in history) {
        try {
          final Map<String, dynamic> menuData = json.decode(jsonString);

          // FIXED: Safe menu parsing with validation
          final komposisi = <MenuComposition>[];

          if (menuData['komposisi'] is List) {
            for (var item in menuData['komposisi']) {
              if (item is Map<String, dynamic>) {
                try {
                  final composition = MenuComposition(
                    namaIngredient: item['nama_ingredient']?.toString() ?? '',
                    jumlahDipakai:
                        _safeParseDouble(item['jumlah_dipakai']) ?? 0.0,
                    satuan: item['satuan']?.toString() ?? 'unit',
                    hargaPerSatuan:
                        _safeParseDouble(item['harga_per_satuan']) ?? 0.0,
                  );

                  if (composition.namaIngredient.isNotEmpty &&
                      composition.jumlahDipakai > 0 &&
                      composition.hargaPerSatuan > 0) {
                    komposisi.add(composition);
                  }
                } catch (e) {
                  developer.log('Skipping invalid composition: $e',
                      name: 'StorageService');
                }
              }
            }
          }

          if (komposisi.isNotEmpty) {
            final menuItem = MenuItem(
              id: menuData['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              namaMenu: menuData['nama_menu']?.toString() ?? '',
              komposisi: komposisi,
              createdAt: _parseDateTime(menuData['created_at']),
            );

            validMenuItems.add(menuItem);
          }
        } catch (e) {
          developer.log('Error parsing menu item: $e', name: 'StorageService');
        }
      }

      return validMenuItems;
    } catch (e) {
      developer.log('Error loading menu history: $e', name: 'StorageService');
      return [];
    }
  }

  // FIXED: Coordinated auto-save with debounce
  static Future<void> autoSave(SharedCalculationData data) async {
    final now = DateTime.now();

    // Debounce
    if (_lastAutoSave != null &&
        now.difference(_lastAutoSave!).inMilliseconds < 1000) {
      return;
    }

    _lastAutoSave = now;

    // Prevent overlapping saves
    if (_isSaving) {
      return;
    }

    final success = await saveSharedData(data);
    if (success) {
      developer.log('Auto-save completed successfully', name: 'StorageService');
    } else {
      developer.log('Auto-save failed', name: 'StorageService');
    }
  }

  // Clear all data
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = [_keySharedData, _keyMenuHistory, _keyKaryawanData];
      bool success = true;

      for (String key in keys) {
        final removed = await prefs.remove(key);
        if (!removed) {
          success = false;
        }
      }

      return success;
    } catch (e) {
      developer.log('Error clearing data: $e', name: 'StorageService');
      return false;
    }
  }

  // HELPER METHODS

  static double _ensureFiniteDouble(double value, double defaultValue) {
    return (value.isFinite && !value.isNaN) ? value : defaultValue;
  }

  static double _validateAndClampDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;

    final parsed = _safeParseDouble(value);
    if (parsed == null) return defaultValue;

    return parsed.clamp(min, max);
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double && value.isFinite) return value;
      if (value is int) return value.toDouble();
      if (value is num) {
        final d = value.toDouble();
        return d.isFinite ? d : null;
      }
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isEmpty) return null;
        final parsed = double.tryParse(cleaned);
        return (parsed?.isFinite == true) ? parsed : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Enhanced data sanitization
  static List<Map<String, dynamic>> _sanitizeVariableCosts(
      List<Map<String, dynamic>> costs) {
    return costs.map((cost) {
      return <String, dynamic>{
        'nama': cost['nama']?.toString() ?? '',
        'totalHarga': _ensureFiniteDouble(
            _safeParseDouble(cost['totalHarga']) ?? 0.0, 0.0),
        'jumlah':
            _ensureFiniteDouble(_safeParseDouble(cost['jumlah']) ?? 0.0, 0.0),
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
        'nominal':
            _ensureFiniteDouble(_safeParseDouble(cost['nominal']) ?? 0.0, 0.0),
        'timestamp':
            cost['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _parseVariableCosts(dynamic data) {
    if (data == null || data is! List) return [];
    try {
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseFixedCosts(dynamic data) {
    if (data == null || data is! List) return [];
    try {
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static bool _validateMenuItem(MenuItem menu) {
    try {
      final nameValidation = InputValidator.validateName(menu.namaMenu);
      if (nameValidation != null) return false;

      for (var komposisi in menu.komposisi) {
        if (komposisi.namaIngredient.trim().isEmpty ||
            komposisi.jumlahDipakai <= 0 ||
            komposisi.hargaPerSatuan <= 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
