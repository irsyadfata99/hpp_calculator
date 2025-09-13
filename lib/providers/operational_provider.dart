// lib/providers/operational_provider.dart - COMPLETE IMPLEMENTATION
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../services/operational_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

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
  // SHARED DATA INTEGRATION
  // ===============================================

  void updateSharedData(SharedCalculationData newSharedData) {
    print('DEBUG: Received data in updateSharedData:');
    print(
        '  estimasiPorsi: ${newSharedData.estimasiPorsi} (${newSharedData.estimasiPorsi.runtimeType})');
    print(
        '  hppMurniPerPorsi: ${newSharedData.hppMurniPerPorsi} (${newSharedData.hppMurniPerPorsi.runtimeType})');

    // Safety check
    if (newSharedData.estimasiPorsi == null ||
        newSharedData.estimasiPorsi == 0) {
      print('WARNING: estimasiPorsi is null or zero, using default');
      newSharedData = newSharedData.copyWith(
        estimasiPorsi: 100.0, // default value
      );
    }

    _sharedData = newSharedData;
    _recalculateOperational();
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
        gajiBulanan: gaji,
        createdAt: DateTime.now(),
      );

      _karyawan = [..._karyawan, newKaryawan];
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
        gajiBulanan: gaji,
        createdAt: _karyawan[index].createdAt,
      );

      final newList = [..._karyawan];
      newList[index] = updatedKaryawan;
      _karyawan = newList;

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
  // CORE CALCULATION METHOD
  // ===============================================

  Future<void> _recalculateOperational() async {
    if (_sharedData == null) {
      _lastCalculationResult = null;
      notifyListeners();
      return;
    }

    try {
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: _karyawan,
        hppMurniPerPorsi: _sharedData!.hppMurniPerPorsi,
        estimasiPorsiPerProduksi: _sharedData!.estimasiPorsi,
        estimasiProduksiBulanan: _sharedData!.estimasiProduksiBulanan,
      );

      _lastCalculationResult = result;

      if (result.isValid) {
        // Update shared data with operational results
        _sharedData = _sharedData!.copyWith(
          karyawan: _karyawan,
          totalOperationalCost: result.totalGajiBulanan,
          totalHargaSetelahOperational: result.totalHargaSetelahOperational,
        );
      }

      notifyListeners();
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ Operational Calculation error: $e');
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
  // EXPORT/IMPORT FUNCTIONALITY
  // ===============================================

  Future<String?> exportData() async {
    try {
      _setLoading(true);
      return await StorageService.exportData();
    } catch (e) {
      _setError('Export failed: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> importData(String jsonData) async {
    try {
      _setLoading(true);
      final success = await StorageService.importData(jsonData);
      if (success) {
        await initializeFromStorage();
        debugPrint('✅ Operational Data imported successfully');
      } else {
        _setError('Import failed: Invalid data format');
      }
      return success;
    } catch (e) {
      _setError('Import failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
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
      estimasiPorsiPerProduksi: _sharedData!.estimasiPorsi,
      estimasiProduksiBulanan: _sharedData!.estimasiProduksiBulanan,
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
    _scheduleAutoSave();
    notifyListeners();
  }

  // ===============================================
  // UTILITY GETTERS
  // ===============================================

  double get totalGajiBulanan {
    return OperationalCalculatorService.calculateTotalGajiBulanan(_karyawan);
  }

  double get operationalCostPerPorsi {
    if (_sharedData == null) return 0.0;

    return OperationalCalculatorService.calculateOperationalCostPerPorsi(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _sharedData!.estimasiPorsi,
      estimasiProduksiBulanan: _sharedData!.estimasiProduksiBulanan,
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
