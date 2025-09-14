// lib/providers/operational_provider.dart - COMPLETE IMPLEMENTATION (No Export/Import)
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../services/operational_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

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
  // SHARED DATA INTEGRATION - FIXED WITH TYPE CONVERSION
  // ===============================================

  void updateSharedData(SharedCalculationData newSharedData) {
    debugPrint('🔄 OperationalProvider.updateSharedData called');

    // FIXED: Ensure all numeric values are properly converted to double
    _sharedData = SharedCalculationData(
      variableCosts: newSharedData.variableCosts,
      fixedCosts: newSharedData.fixedCosts,
      // EXPLICIT DOUBLE CONVERSION - This fixes the type issue
      estimasiPorsi: _ensureDouble(newSharedData.estimasiPorsi),
      estimasiProduksiBulanan:
          _ensureDouble(newSharedData.estimasiProduksiBulanan),
      hppMurniPerPorsi: _ensureDouble(newSharedData.hppMurniPerPorsi),
      biayaVariablePerPorsi: _ensureDouble(newSharedData.biayaVariablePerPorsi),
      biayaFixedPerPorsi: _ensureDouble(newSharedData.biayaFixedPerPorsi),
      karyawan: _karyawan, // Use local karyawan data
      totalOperationalCost: _ensureDouble(newSharedData.totalOperationalCost),
      totalHargaSetelahOperational:
          _ensureDouble(newSharedData.totalHargaSetelahOperational),
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
  }

  // FIXED: Helper method for safe double conversion
  double _ensureDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // ===============================================
  // KARYAWAN CRUD METHODS - WITH AUTO SAVE
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

    final gajiValidation = InputValidator.validateSalary(gaji.toString());
    if (gajiValidation != null) {
      _setError('Gaji: $gajiValidation');
      return;
    }

    // Business validation
    if (gaji < 100000) {
      _setError('Gaji terlalu rendah (minimal Rp 100.000)');
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
        gajiBulanan: _ensureDouble(gaji), // FIXED: Ensure double
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

    final gajiValidation = InputValidator.validateSalary(gaji.toString());
    if (gajiValidation != null) {
      _setError('Gaji: $gajiValidation');
      return;
    }

    _setLoading(true);
    try {
      final updatedKaryawan = KaryawanData(
        id: _karyawan[index].id,
        namaKaryawan: nama.trim(),
        jabatan: jabatan.trim(),
        gajiBulanan: _ensureDouble(gaji), // FIXED: Ensure double
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
  // CORE CALCULATION METHOD - FIXED WITH TYPE CONVERSION
  // ===============================================

  Future<void> _recalculateOperational() async {
    debugPrint('🧮 OperationalProvider._recalculateOperational called');

    if (_sharedData == null) {
      debugPrint('⚠️ SharedData is null, skipping calculation');
      _lastCalculationResult = null;
      notifyListeners();
      return;
    }

    // ENSURE DOUBLE TYPES BEFORE CALCULATION
    double estimasiPorsi = _ensureDouble(_sharedData!.estimasiPorsi);
    double estimasiProduksiBulanan =
        _ensureDouble(_sharedData!.estimasiProduksiBulanan);
    double hppMurniPerPorsi = _ensureDouble(_sharedData!.hppMurniPerPorsi);

    debugPrint('📊 Input values for calculation (VERIFIED DOUBLE):');
    debugPrint(
        '  estimasiPorsi: $estimasiPorsi (${estimasiPorsi.runtimeType})');
    debugPrint(
        '  estimasiProduksiBulanan: $estimasiProduksiBulanan (${estimasiProduksiBulanan.runtimeType})');
    debugPrint(
        '  hppMurniPerPorsi: $hppMurniPerPorsi (${hppMurniPerPorsi.runtimeType})');
    debugPrint('  karyawan count: ${_karyawan.length}');

    try {
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: _karyawan,
        hppMurniPerPorsi: hppMurniPerPorsi,
        estimasiPorsiPerProduksi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      debugPrint('✅ Calculation completed:');
      debugPrint('  result.isValid: ${result.isValid}');
      debugPrint(
          '  result.totalGajiBulanan: ${AppFormatters.formatRupiah(result.totalGajiBulanan)}');
      debugPrint(
          '  result.operationalCostPerPorsi: ${AppFormatters.formatRupiah(result.operationalCostPerPorsi)}');

      _lastCalculationResult = result;

      if (result.isValid) {
        // Update shared data with operational results using explicit double conversion
        _sharedData = _sharedData!.copyWith(
          karyawan: _karyawan,
          totalOperationalCost: _ensureDouble(result.totalGajiBulanan),
          totalHargaSetelahOperational:
              _ensureDouble(result.totalHargaSetelahOperational),
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
  // ANALYSIS METHODS
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
      totalPorsiBulanan: _lastCalculationResult!.totalPorsiBulanan,
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
      estimasiPorsiPerProduksi: _ensureDouble(_sharedData!.estimasiPorsi),
      estimasiProduksiBulanan:
          _ensureDouble(_sharedData!.estimasiProduksiBulanan),
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
        totalHargaSetelahOperational:
            _ensureDouble(_sharedData!.hppMurniPerPorsi), // Reset to HPP only
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
      estimasiPorsiPerProduksi: _ensureDouble(_sharedData!.estimasiPorsi),
      estimasiProduksiBulanan:
          _ensureDouble(_sharedData!.estimasiProduksiBulanan),
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
