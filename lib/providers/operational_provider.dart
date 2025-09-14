// lib/providers/operational_provider.dart - FIXED NULL SAFETY VERSION
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../services/operational_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class OperationalProvider with ChangeNotifier {
  List<KaryawanData> _karyawan = [];
  String? _errorMessage;
  bool _isLoading = false;
  OperationalCalculationResult? _lastCalculationResult;

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Reference to shared data (will be injected)
  SharedCalculationData? _sharedData;

  // Getters
  List<KaryawanData> get karyawan => _karyawan;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  OperationalCalculationResult? get lastCalculationResult =>
      _lastCalculationResult;
  SharedCalculationData? get sharedData => _sharedData;

  // ===============================================
  // INITIALIZATION WITH STORAGE
  // ===============================================

  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _karyawan = savedData.karyawan;
        _sharedData = savedData;
        await _recalculateOperational();
        debugPrint(
            '✅ Operational Data loaded from storage: ${_karyawan.length} karyawan');
      } else {
        debugPrint('ℹ️ No saved operational data found, using defaults');
      }
      _setError(null);
    } catch (e) {
      _setError('Error loading operational data: ${e.toString()}');
      debugPrint('❌ Error loading operational from storage: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // SHARED DATA INTEGRATION - FIXED WITH COMPREHENSIVE TYPE SAFETY
  // ===============================================

  void updateSharedData(SharedCalculationData newSharedData) {
    debugPrint('🔄 OperationalProvider.updateSharedData called');

    try {
      // FIXED: Comprehensive null-safe conversion with validation
      _sharedData = SharedCalculationData(
        variableCosts: newSharedData.variableCosts,
        fixedCosts: newSharedData.fixedCosts,
        // EXPLICIT SAFE CONVERSION - This fixes the type issue
        estimasiPorsi: _ensureDoubleOrDefault(
            newSharedData.estimasiPorsi, AppConstants.defaultEstimasiPorsi),
        estimasiProduksiBulanan: _ensureDoubleOrDefault(
            newSharedData.estimasiProduksiBulanan,
            AppConstants.defaultEstimasiProduksi),
        hppMurniPerPorsi:
            _ensureDoubleOrDefault(newSharedData.hppMurniPerPorsi, 0.0),
        biayaVariablePerPorsi:
            _ensureDoubleOrDefault(newSharedData.biayaVariablePerPorsi, 0.0),
        biayaFixedPerPorsi:
            _ensureDoubleOrDefault(newSharedData.biayaFixedPerPorsi, 0.0),
        karyawan: _karyawan, // Use local karyawan data
        totalOperationalCost:
            _ensureDoubleOrDefault(newSharedData.totalOperationalCost, 0.0),
        totalHargaSetelahOperational: _ensureDoubleOrDefault(
            newSharedData.totalHargaSetelahOperational, 0.0),
      );

      debugPrint('📊 Updated shared data values (FIXED TYPES):');
      debugPrint(
          '  estimasiPorsi: ${_sharedData!.estimasiPorsi} (${_sharedData!.estimasiPorsi.runtimeType})');
      debugPrint(
          '  estimasiProduksiBulanan: ${_sharedData!.estimasiProduksiBulanan} (${_sharedData!.estimasiProduksiBulanan.runtimeType})');
      debugPrint(
          '  hppMurniPerPorsi: ${_sharedData!.hppMurniPerPorsi} (${_sharedData!.hppMurniPerPorsi.runtimeType})');
      debugPrint('  karyawan count: ${_karyawan.length}');

      _recalculateOperational();
    } catch (e) {
      debugPrint('❌ Error updating shared data: $e');
      _setError('Error updating shared data: ${e.toString()}');
    }
  }

  // FIXED: Enhanced helper method with comprehensive null and edge case handling
  double _ensureDoubleOrDefault(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    try {
      if (value is double) {
        return value.isFinite ? value : defaultValue;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        if (value.trim().isEmpty) return defaultValue;
        // Clean string dari formatting
        String cleanValue = value.replaceAll(RegExp(r'[^\d\.]'), '');
        if (cleanValue.isEmpty) return defaultValue;

        final parsed = double.tryParse(cleanValue);
        if (parsed != null && parsed.isFinite && parsed >= 0) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('🚨 Error ensuring double: $value -> $e');
    }

    return defaultValue;
  }

  // ===============================================
  // KARYAWAN CRUD METHODS - WITH ENHANCED VALIDATION
  // ===============================================

  Future<void> addKaryawan(String nama, String jabatan, double gaji) async {
    // Comprehensive validation
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _setError('Nama karyawan: $namaValidation');
      return;
    }

    final jabatanValidation = InputValidator.validateName(jabatan);
    if (jabatanValidation != null) {
      _setError('Jabatan: $jabatanValidation');
      return;
    }

    // FIXED: Safe gaji validation
    final safeGaji = _ensureDoubleOrDefault(gaji, 0.0);
    final salaryValidation = InputValidator.validateSalaryDirect(safeGaji);
    if (salaryValidation != null) {
      _setError('Gaji: $salaryValidation');
      return;
    }

    // Business validation
    if (safeGaji < AppConstants.minSalary) {
      _setError(
          'Gaji terlalu rendah (minimal ${AppFormatters.formatRupiah(AppConstants.minSalary)})');
      return;
    }

    // Check for duplicate names
    bool isDuplicate = _karyawan.any((k) =>
        k.namaKaryawan.toLowerCase().trim() == nama.toLowerCase().trim());

    if (isDuplicate) {
      _setError('Nama karyawan sudah ada. Gunakan nama yang berbeda.');
      return;
    }

    _setLoading(true);
    try {
      final newKaryawan = KaryawanData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaKaryawan: nama.trim(),
        jabatan: jabatan.trim(),
        gajiBulanan: safeGaji,
        createdAt: DateTime.now(),
      );

      _karyawan = [..._karyawan, newKaryawan];

      // FIXED: Update shared data with new karyawan list
      if (_sharedData != null) {
        _sharedData = _sharedData!.copyWith(karyawan: _karyawan);
      }

      await _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ Karyawan added: $nama');
    } catch (e) {
      _setError('Error adding karyawan: ${e.toString()}');
      debugPrint('❌ Error adding karyawan: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateKaryawan(
      int index, String nama, String jabatan, double gaji) async {
    if (index < 0 || index >= _karyawan.length) {
      _setError('Index karyawan tidak valid');
      return;
    }

    // Validate inputs
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _setError('Nama karyawan: $namaValidation');
      return;
    }

    final jabatanValidation = InputValidator.validateName(jabatan);
    if (jabatanValidation != null) {
      _setError('Jabatan: $jabatanValidation');
      return;
    }

    // FIXED: Safe gaji validation
    final safeGaji = _ensureDoubleOrDefault(gaji, 0.0);
    final salaryValidation = InputValidator.validateSalaryDirect(safeGaji);
    if (salaryValidation != null) {
      _setError('Gaji: $salaryValidation');
      return;
    }

    _setLoading(true);
    try {
      final updatedKaryawan = KaryawanData(
        id: _karyawan[index].id,
        namaKaryawan: nama.trim(),
        jabatan: jabatan.trim(),
        gajiBulanan: safeGaji,
        createdAt: _karyawan[index].createdAt,
      );

      final newList = [..._karyawan];
      newList[index] = updatedKaryawan;
      _karyawan = newList;

      // FIXED: Update shared data with new karyawan list
      if (_sharedData != null) {
        _sharedData = _sharedData!.copyWith(karyawan: _karyawan);
      }

      await _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ Karyawan updated: $nama');
    } catch (e) {
      _setError('Error updating karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeKaryawan(int index) async {
    if (index < 0 || index >= _karyawan.length) {
      _setError('Index karyawan tidak valid');
      return;
    }

    _setLoading(true);
    try {
      final removedName = _karyawan[index].namaKaryawan;
      final newList = [..._karyawan];
      newList.removeAt(index);
      _karyawan = newList;

      // FIXED: Update shared data with new karyawan list
      if (_sharedData != null) {
        _sharedData = _sharedData!.copyWith(karyawan: _karyawan);
      }

      await _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ Karyawan removed: $removedName');
    } catch (e) {
      _setError('Error removing karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAllKaryawan() async {
    _setLoading(true);
    try {
      _karyawan = [];

      // FIXED: Update shared data with empty karyawan list
      if (_sharedData != null) {
        _sharedData = _sharedData!.copyWith(karyawan: _karyawan);
      }

      await _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ All karyawan cleared');
    } catch (e) {
      _setError('Error clearing karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // CORE CALCULATION METHOD - FIXED WITH COMPREHENSIVE ERROR HANDLING
  // ===============================================

  Future<void> _recalculateOperational() async {
    debugPrint('🧮 OperationalProvider._recalculateOperational called');

    if (_sharedData == null) {
      debugPrint('⚠️ SharedData is null, skipping calculation');
      _lastCalculationResult = null;
      notifyListeners();
      return;
    }

    try {
      // ENSURE SAFE VALUES BEFORE CALCULATION
      double estimasiPorsi = _ensureDoubleOrDefault(
          _sharedData!.estimasiPorsi, AppConstants.defaultEstimasiPorsi);
      double estimasiProduksiBulanan = _ensureDoubleOrDefault(
          _sharedData!.estimasiProduksiBulanan,
          AppConstants.defaultEstimasiProduksi);
      double hppMurniPerPorsi =
          _ensureDoubleOrDefault(_sharedData!.hppMurniPerPorsi, 0.0);

      debugPrint('📊 Input values for calculation (VERIFIED SAFE):');
      debugPrint(
          '  estimasiPorsi: $estimasiPorsi (${estimasiPorsi.runtimeType})');
      debugPrint(
          '  estimasiProduksiBulanan: $estimasiProduksiBulanan (${estimasiProduksiBulanan.runtimeType})');
      debugPrint(
          '  hppMurniPerPorsi: $hppMurniPerPorsi (${hppMurniPerPorsi.runtimeType})');
      debugPrint('  karyawan count: ${_karyawan.length}');

      // Validate that all karyawan have valid data
      List<KaryawanData> validKaryawan =
          _karyawan.where((k) => k.isValid).toList();
      if (validKaryawan.length != _karyawan.length) {
        debugPrint('⚠️ Some karyawan have invalid data, using only valid ones');
      }

      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: validKaryawan,
        hppMurniPerPorsi: hppMurniPerPorsi,
        estimasiPorsiPerProduksi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      debugPrint('✅ Calculation completed:');
      debugPrint('  result.isValid: ${result.isValid}');
      if (result.isValid) {
        debugPrint(
            '  result.totalGajiBulanan: ${AppFormatters.formatRupiah(result.totalGajiBulanan)}');
        debugPrint(
            '  result.operationalCostPerPorsi: ${AppFormatters.formatRupiah(result.operationalCostPerPorsi)}');
      }

      _lastCalculationResult = result;

      if (result.isValid) {
        // Update shared data with operational results using safe conversion
        _sharedData = _sharedData!.copyWith(
          karyawan: validKaryawan,
          totalOperationalCost:
              _ensureDoubleOrDefault(result.totalGajiBulanan, 0.0),
          totalHargaSetelahOperational:
              _ensureDoubleOrDefault(result.totalHargaSetelahOperational, 0.0),
        );
        debugPrint('✅ SharedData updated with calculation results');
      } else {
        debugPrint('❌ Calculation failed: ${result.errorMessage}');
      }

      notifyListeners();
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ Operational Calculation error: $e');
      _setError('Calculation error: ${e.toString()}');
      notifyListeners();
    }
  }

  // ===============================================
  // AUTO-SAVE FUNCTIONALITY
  // ===============================================

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    if (_sharedData == null) return;

    try {
      await StorageService.autoSave(_sharedData!);
      debugPrint(
          '💾 Operational Auto-save completed: ${_karyawan.length} karyawan');
    } catch (e) {
      debugPrint('❌ Operational Auto-save failed: $e');
    }
  }

  // ===============================================
  // ANALYSIS METHODS - FIXED WITH NULL SAFETY
  // ===============================================

  Map<String, dynamic> getEfficiencyAnalysis() {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data belum lengkap untuk analisis',
      };
    }

    return OperationalCalculatorService.analyzeKaryawanEfficiency(
      karyawan: _karyawan,
      totalPorsiBulanan: _ensureDoubleOrDefault(
          _lastCalculationResult!.totalPorsiBulanan, 0.0),
    );
  }

  Map<String, dynamic> getProjectionAnalysis() {
    if (_sharedData == null) {
      return {
        'isAvailable': false,
        'message': 'Data belum tersedia untuk proyeksi',
      };
    }

    return OperationalCalculatorService.calculateOperationalProjection(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _ensureDoubleOrDefault(
          _sharedData!.estimasiPorsi, AppConstants.defaultEstimasiPorsi),
      estimasiProduksiBulanan: _ensureDoubleOrDefault(
          _sharedData!.estimasiProduksiBulanan,
          AppConstants.defaultEstimasiProduksi),
    );
  }

  // ===============================================
  // HELPER METHODS
  // ===============================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetData() {
    _karyawan = [];
    _lastCalculationResult = null;
    _errorMessage = null;
    _isLoading = false;

    // FIXED: Update shared data when resetting with type safety
    if (_sharedData != null) {
      _sharedData = _sharedData!.copyWith(
        karyawan: _karyawan,
        totalOperationalCost: 0.0,
        totalHargaSetelahOperational: _ensureDoubleOrDefault(
            _sharedData!.hppMurniPerPorsi, 0.0), // Reset to HPP only
      );
    }

    _scheduleAutoSave();
    notifyListeners();
  }

  // ===============================================
  // UTILITY GETTERS WITH TYPE SAFETY
  // ===============================================

  double get totalGajiBulanan {
    return OperationalCalculatorService.calculateTotalGajiBulanan(_karyawan);
  }

  double get operationalCostPerPorsi {
    if (_sharedData == null) return 0.0;

    return OperationalCalculatorService.calculateOperationalCostPerPorsi(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _ensureDoubleOrDefault(
          _sharedData!.estimasiPorsi, AppConstants.defaultEstimasiPorsi),
      estimasiProduksiBulanan: _ensureDoubleOrDefault(
          _sharedData!.estimasiProduksiBulanan,
          AppConstants.defaultEstimasiProduksi),
    );
  }

  String get formattedTotalGaji {
    return OperationalCalculatorService.formatRupiah(totalGajiBulanan);
  }

  String get formattedOperationalPerPorsi {
    return OperationalCalculatorService.formatRupiah(operationalCostPerPorsi);
  }

  bool get hasKaryawan => _karyawan.isNotEmpty;

  bool get isCalculationReady {
    return _karyawan.isNotEmpty && _sharedData != null;
  }

  int get karyawanCount => _karyawan.length;

  Map<String, dynamic> get calculationSummary {
    return {
      'totalKaryawan': _karyawan.length,
      'totalGaji': totalGajiBulanan,
      'operationalPerPorsi': operationalCostPerPorsi,
      'isValid': _lastCalculationResult?.isValid ?? false,
      'hasSharedData': _sharedData != null,
      'lastCalculated': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
