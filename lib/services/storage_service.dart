// lib/services/storage_service.dart - HIGH PRIORITY FIX: Data Loss Prevention + Enhanced Coordination
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

  // HIGH PRIORITY FIX: Enhanced auto-save coordination with queue system
  static DateTime? _lastAutoSave;
  static bool _isSaving = false;
  static final List<SharedCalculationData> _saveQueue = [];
  static bool _isProcessingQueue = false;

  // Private constructor
  StorageService._();

  // HIGH PRIORITY FIX: Enhanced coordinated save with retry mechanism
  static Future<bool> saveSharedData(SharedCalculationData data) async {
    if (_isSaving) {
      developer.log('Save in progress, adding to queue...',
          name: 'StorageService');
      _saveQueue.add(data);
      _processSaveQueue(); // Process queue asynchronously
      return true; // Return true since it's queued
    }

    _isSaving = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // HIGH PRIORITY FIX: Enhanced JSON serialization with comprehensive validation
      final jsonData = <String, dynamic>{
        'version': AppConstants.appVersion,
        'timestamp': DateTime.now().toIso8601String(),

        // HIGH PRIORITY FIX: Enhanced data validation before save
        'variableCosts': _sanitizeAndValidateVariableCosts(data.variableCosts),
        'fixedCosts': _sanitizeAndValidateFixedCosts(data.fixedCosts),
        'estimasiPorsi': _ensureValidDouble(
            data.estimasiPorsi,
            AppConstants.defaultEstimasiPorsi,
            AppConstants.minQuantity,
            AppConstants.maxQuantity),
        'estimasiProduksiBulanan': _ensureValidDouble(
            data.estimasiProduksiBulanan,
            AppConstants.defaultEstimasiProduksi,
            AppConstants.minQuantity,
            AppConstants.maxQuantity),
        'hppMurniPerPorsi': _ensureValidDouble(
            data.hppMurniPerPorsi, 0.0, 0.0, AppConstants.maxPrice),
        'biayaVariablePerPorsi': _ensureValidDouble(
            data.biayaVariablePerPorsi, 0.0, 0.0, AppConstants.maxPrice),
        'biayaFixedPerPorsi': _ensureValidDouble(
            data.biayaFixedPerPorsi, 0.0, 0.0, AppConstants.maxPrice),

        // Operational Data - HIGH PRIORITY FIX: Additional validation
        'totalOperationalCost': _ensureValidDouble(
            data.totalOperationalCost, 0.0, 0.0, AppConstants.maxPrice * 10),
        'totalHargaSetelahOperational': _ensureValidDouble(
            data.totalHargaSetelahOperational, 0.0, 0.0, AppConstants.maxPrice),
      };

      // HIGH PRIORITY FIX: Validate JSON before saving
      if (!_validateJsonData(jsonData)) {
        developer.log('JSON validation failed, skipping save',
            name: 'StorageService');
        return false;
      }

      final jsonString = json.encode(jsonData);

      // HIGH PRIORITY FIX: Retry mechanism for save operations
      bool sharedResult = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          sharedResult = await prefs.setString(_keySharedData, jsonString);
          if (sharedResult) break;

          developer.log('Save attempt $attempt failed, retrying...',
              name: 'StorageService');
          await Future.delayed(Duration(milliseconds: 100 * attempt));
        } catch (e) {
          developer.log('Save attempt $attempt error: $e',
              name: 'StorageService');
          if (attempt == 3) rethrow;
        }
      }

      // HIGH PRIORITY FIX: Save karyawan data separately with validation
      final karyawanResult =
          await _saveKaryawanDataWithValidation(data.karyawan);

      developer.log(
          'SharedData saved: $sharedResult, Karyawan saved: $karyawanResult',
          name: 'StorageService');

      return sharedResult && karyawanResult;
    } catch (e) {
      developer.log('Error saving data: $e', name: 'StorageService');
      return false;
    } finally {
      _isSaving = false;
      _processSaveQueue(); // Process any queued saves
    }
  }

  // HIGH PRIORITY FIX: Queue processor for handling multiple save requests
  static Future<void> _processSaveQueue() async {
    if (_isProcessingQueue || _saveQueue.isEmpty || _isSaving) {
      return;
    }

    _isProcessingQueue = true;

    while (_saveQueue.isNotEmpty && !_isSaving) {
      final data = _saveQueue.removeAt(0);

      try {
        await saveSharedData(data);
        await Future.delayed(
            const Duration(milliseconds: 50)); // Small delay between saves
      } catch (e) {
        developer.log('Queue processing error: $e', name: 'StorageService');
      }
    }

    _isProcessingQueue = false;
  }

  // HIGH PRIORITY FIX: Enhanced load with comprehensive error recovery
  static Future<SharedCalculationData?> loadSharedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load shared data
      final String? sharedJsonString = prefs.getString(_keySharedData);
      if (sharedJsonString == null || sharedJsonString.isEmpty) {
        developer.log('No shared data found', name: 'StorageService');
        return null;
      }

      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(sharedJsonString);
      } catch (e) {
        developer.log('JSON decode error, attempting recovery: $e',
            name: 'StorageService');
        return _attemptDataRecovery(prefs);
      }

      // HIGH PRIORITY FIX: Load karyawan data separately with validation
      final List<KaryawanData> karyawan =
          await _loadKaryawanDataWithValidation();

      // HIGH PRIORITY FIX: Enhanced data validation during load
      final sharedData = SharedCalculationData(
        variableCosts:
            _parseAndValidateVariableCosts(jsonData['variableCosts']),
        fixedCosts: _parseAndValidateFixedCosts(jsonData['fixedCosts']),
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

      // HIGH PRIORITY FIX: Final validation of loaded data
      if (!_validateLoadedData(sharedData)) {
        developer.log('Loaded data validation failed, returning default',
            name: 'StorageService');
        return SharedCalculationData();
      }

      developer.log(
          'Data loaded successfully: ${sharedData.totalItemCount} items, ${karyawan.length} karyawan',
          name: 'StorageService');
      return sharedData;
    } catch (e) {
      developer.log('Error loading data: $e', name: 'StorageService');
      return null;
    }
  }

  // HIGH PRIORITY FIX: Data recovery mechanism
  static Future<SharedCalculationData?> _attemptDataRecovery(
      SharedPreferences prefs) async {
    try {
      // Try to recover karyawan data separately
      final karyawan = await _loadKaryawanDataWithValidation();

      if (karyawan.isNotEmpty) {
        developer.log(
            'Partial recovery successful: ${karyawan.length} karyawan',
            name: 'StorageService');
        return SharedCalculationData(karyawan: karyawan);
      }

      return SharedCalculationData();
    } catch (e) {
      developer.log('Data recovery failed: $e', name: 'StorageService');
      return SharedCalculationData();
    }
  }

  // HIGH PRIORITY FIX: Enhanced karyawan data management with validation
  static Future<bool> _saveKaryawanDataWithValidation(
      List<KaryawanData> karyawan) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // HIGH PRIORITY FIX: Validate each karyawan before saving
      final validKaryawan = <KaryawanData>[];
      for (var k in karyawan) {
        if (_validateKaryawanData(k)) {
          validKaryawan.add(k);
        } else {
          developer.log('Invalid karyawan data skipped: ${k.namaKaryawan}',
              name: 'StorageService');
        }
      }

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

  static Future<List<KaryawanData>> _loadKaryawanDataWithValidation() async {
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
            if (_validateKaryawanData(karyawan)) {
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

  // HIGH PRIORITY FIX: Enhanced menu history management with validation
  static Future<bool> saveMenuToHistory(MenuItem menu) async {
    try {
      if (!_validateMenuItem(menu)) {
        developer.log('Menu validation failed', name: 'StorageService');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_keyMenuHistory) ?? [];

      // HIGH PRIORITY FIX: Enhanced menu data validation
      final menuData = {
        'id': menu.id,
        'nama_menu': menu.namaMenu,
        'komposisi': menu.komposisi
            .where((item) => _validateMenuComposition(item))
            .map((item) => {
                  'nama_ingredient': item.namaIngredient,
                  'jumlah_dipakai': _ensureValidDouble(item.jumlahDipakai, 0.0,
                      AppConstants.minQuantity, AppConstants.maxQuantity),
                  'satuan': item.satuan,
                  'harga_per_satuan': _ensureValidDouble(item.hargaPerSatuan,
                      0.0, AppConstants.minPrice, AppConstants.maxPrice),
                })
            .toList(),
        'created_at': menu.createdAt.toIso8601String(),
        'version': AppConstants.appVersion,
      };

      if (menuData['komposisi'] == null ||
          (menuData['komposisi'] as List).isEmpty) {
        developer.log('Menu has no valid compositions', name: 'StorageService');
        return false;
      }

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

          // HIGH PRIORITY FIX: Enhanced menu parsing with validation
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

                  if (_validateMenuComposition(composition)) {
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

  // HIGH PRIORITY FIX: Enhanced coordinated auto-save with queue protection
  static Future<void> autoSave(SharedCalculationData data) async {
    final now = DateTime.now();

    // HIGH PRIORITY FIX: Enhanced debounce with validation
    if (_lastAutoSave != null &&
        now.difference(_lastAutoSave!).inMilliseconds < 1000) {
      return;
    }

    // HIGH PRIORITY FIX: Validate data before auto-save
    if (!_validateAutoSaveData(data)) {
      developer.log('Auto-save skipped: invalid data', name: 'StorageService');
      return;
    }

    _lastAutoSave = now;

    // HIGH PRIORITY FIX: Queue-based auto-save
    if (_isSaving) {
      _saveQueue.add(data);
      developer.log('Auto-save queued', name: 'StorageService');
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

      // HIGH PRIORITY FIX: Clear queues on data clear
      _saveQueue.clear();
      _lastAutoSave = null;

      return success;
    } catch (e) {
      developer.log('Error clearing data: $e', name: 'StorageService');
      return false;
    }
  }

  // HIGH PRIORITY FIX: COMPREHENSIVE VALIDATION METHODS

  static double _ensureValidDouble(double value, double defaultValue,
      [double? min, double? max]) {
    if (!value.isFinite || value.isNaN) return defaultValue;
    if (min != null && value < min) return defaultValue;
    if (max != null && value > max) return defaultValue;
    return value;
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

  // HIGH PRIORITY FIX: Enhanced data sanitization with validation
  static List<Map<String, dynamic>> _sanitizeAndValidateVariableCosts(
      List<Map<String, dynamic>> costs) {
    return costs.where((cost) => _validateVariableCostItem(cost)).map((cost) {
      return <String, dynamic>{
        'nama': cost['nama']?.toString() ?? '',
        'totalHarga': _ensureValidDouble(
            _safeParseDouble(cost['totalHarga']) ?? 0.0,
            0.0,
            AppConstants.minPrice,
            AppConstants.maxPrice),
        'jumlah': _ensureValidDouble(_safeParseDouble(cost['jumlah']) ?? 0.0,
            0.0, AppConstants.minQuantity, AppConstants.maxQuantity),
        'satuan': cost['satuan']?.toString() ?? 'unit',
        'timestamp':
            cost['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _sanitizeAndValidateFixedCosts(
      List<Map<String, dynamic>> costs) {
    return costs.where((cost) => _validateFixedCostItem(cost)).map((cost) {
      return <String, dynamic>{
        'jenis': cost['jenis']?.toString() ?? '',
        'nominal': _ensureValidDouble(_safeParseDouble(cost['nominal']) ?? 0.0,
            0.0, AppConstants.minPrice, AppConstants.maxPrice),
        'timestamp':
            cost['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _parseAndValidateVariableCosts(
      dynamic data) {
    if (data == null || data is! List) return [];

    try {
      return data
          .cast<Map<String, dynamic>>()
          .where((item) => _validateVariableCostItem(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseAndValidateFixedCosts(dynamic data) {
    if (data == null || data is! List) return [];

    try {
      return data
          .cast<Map<String, dynamic>>()
          .where((item) => _validateFixedCostItem(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // HIGH PRIORITY FIX: Comprehensive validation methods
  static bool _validateJsonData(Map<String, dynamic> jsonData) {
    try {
      // Check required fields
      if (jsonData['version'] == null) return false;
      if (jsonData['variableCosts'] == null) return false;
      if (jsonData['fixedCosts'] == null) return false;

      // Validate numeric fields
      final estimasiPorsi = _safeParseDouble(jsonData['estimasiPorsi']);
      if (estimasiPorsi == null || estimasiPorsi <= 0) return false;

      final estimasiProduksi =
          _safeParseDouble(jsonData['estimasiProduksiBulanan']);
      if (estimasiProduksi == null || estimasiProduksi <= 0) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateLoadedData(SharedCalculationData data) {
    try {
      if (data.estimasiPorsi <= 0 || data.estimasiProduksiBulanan <= 0)
        return false;
      if (data.estimasiPorsi > AppConstants.maxQuantity ||
          data.estimasiProduksiBulanan > AppConstants.maxQuantity) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateAutoSaveData(SharedCalculationData data) {
    try {
      // Basic validation
      if (data.estimasiPorsi <= 0 || data.estimasiProduksiBulanan <= 0)
        return false;

      // Check for reasonable values
      if (data.hppMurniPerPorsi < 0 ||
          data.hppMurniPerPorsi > AppConstants.maxPrice) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateVariableCostItem(Map<String, dynamic> item) {
    try {
      final nama = item['nama']?.toString() ?? '';
      if (nama.isEmpty || nama.length > AppConstants.maxTextLength)
        return false;

      final totalHarga = _safeParseDouble(item['totalHarga']);
      if (totalHarga == null ||
          totalHarga <= 0 ||
          totalHarga > AppConstants.maxPrice) return false;

      final jumlah = _safeParseDouble(item['jumlah']);
      if (jumlah == null || jumlah <= 0 || jumlah > AppConstants.maxQuantity)
        return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateFixedCostItem(Map<String, dynamic> item) {
    try {
      final jenis = item['jenis']?.toString() ?? '';
      if (jenis.isEmpty || jenis.length > AppConstants.maxTextLength)
        return false;

      final nominal = _safeParseDouble(item['nominal']);
      if (nominal == null || nominal <= 0 || nominal > AppConstants.maxPrice)
        return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateKaryawanData(KaryawanData karyawan) {
    try {
      if (!karyawan.isValid) return false;
      if (karyawan.gajiBulanan < AppConstants.minSalary ||
          karyawan.gajiBulanan > AppConstants.maxSalary) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateMenuItem(MenuItem menu) {
    try {
      final nameValidation = InputValidator.validateName(menu.namaMenu);
      if (nameValidation != null) return false;

      for (var komposisi in menu.komposisi) {
        if (!_validateMenuComposition(komposisi)) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _validateMenuComposition(MenuComposition composition) {
    try {
      if (composition.namaIngredient.trim().isEmpty) return false;
      if (composition.namaIngredient.length > AppConstants.maxTextLength)
        return false;
      if (composition.jumlahDipakai <= 0 || !composition.jumlahDipakai.isFinite)
        return false;
      if (composition.jumlahDipakai > AppConstants.maxQuantity) return false;
      if (composition.hargaPerSatuan <= 0 ||
          !composition.hargaPerSatuan.isFinite) return false;
      if (composition.hargaPerSatuan > AppConstants.maxPrice) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
