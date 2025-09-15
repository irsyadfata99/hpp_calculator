// lib/providers/operational_provider.dart - FIXED: Simplified without circular dependencies
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
  Timer? _autoSaveTimer;

  // Reference data from HPP (read-only)
  SharedCalculationData? _hppData;

  // Getters
  List<KaryawanData> get karyawan => _karyawan;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  OperationalCalculationResult? get lastCalculationResult =>
      _lastCalculationResult;
  SharedCalculationData? get hppData => _hppData;

  // INITIALIZATION
  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _karyawan = savedData.karyawan;
        _hppData = savedData;
        _recalculateOperational();
        debugPrint('✅ Operational Data loaded: ${_karyawan.length} karyawan');
      }
      _setError(null);
    } catch (e) {
      _setError('Error loading operational data: ${e.toString()}');
      debugPrint('❌ Error loading operational: $e');
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Simple update from HPP without circular dependency
  void updateFromHPP(SharedCalculationData hppData) {
    try {
      _hppData =
          hppData.copyWith(karyawan: _karyawan); // Keep our karyawan data
      _recalculateOperational();
    } catch (e) {
      debugPrint('❌ Error updating from HPP: $e');
    }
  }

  // KARYAWAN CRUD METHODS
  Future<void> addKaryawan(String nama, String jabatan, double gaji) async {
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

    final salaryValidation = InputValidator.validateSalaryDirect(gaji);
    if (salaryValidation != null) {
      _setError('Gaji: $salaryValidation');
      return;
    }

    if (gaji < AppConstants.minSalary) {
      _setError(
          'Gaji terlalu rendah (minimal ${AppFormatters.formatRupiah(AppConstants.minSalary)})');
      return;
    }

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
      _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ Karyawan added: $nama');
    } catch (e) {
      _setError('Error adding karyawan: ${e.toString()}');
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
      _karyawan = [..._karyawan]..removeAt(index);

      _recalculateOperational();
      _setError(null);
      _scheduleAutoSave();
      debugPrint('✅ Karyawan removed: $removedName');
    } catch (e) {
      _setError('Error removing karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // CORE CALCULATION - FIXED: With division by zero protection
  void _recalculateOperational() {
    if (_hppData == null) {
      _lastCalculationResult = null;
      return;
    }

    try {
      // FIXED: Division by zero protection
      double estimasiPorsi = _hppData!.estimasiPorsi;
      double estimasiProduksi = _hppData!.estimasiProduksiBulanan;
      double hppMurni = _hppData!.hppMurniPerPorsi;

      if (estimasiPorsi <= 0 || estimasiProduksi <= 0) {
        debugPrint('⚠️ Invalid estimation values, skipping calculation');
        _lastCalculationResult = null;
        return;
      }

      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: _karyawan,
        hppMurniPerPorsi: hppMurni,
        estimasiPorsiPerProduksi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksi,
      );

      _lastCalculationResult = result;

      if (result.isValid) {
        // Update our local hpp data copy
        _hppData = _hppData!.copyWith(
          karyawan: _karyawan,
          totalOperationalCost: result.totalGajiBulanan,
          totalHargaSetelahOperational: result.totalHargaSetelahOperational,
        );
      }
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ Operational calculation error: $e');
    }
  }

  // AUTO-SAVE
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    if (_hppData == null) return;

    try {
      await StorageService.autoSave(_hppData!);
      debugPrint('💾 Operational Auto-save completed');
    } catch (e) {
      debugPrint('❌ Operational Auto-save failed: $e');
    }
  }

  // ANALYSIS METHODS - FIXED: With null safety
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
    if (_hppData == null) {
      return {
        'isAvailable': false,
        'message': 'Data belum tersedia untuk proyeksi',
      };
    }

    return OperationalCalculatorService.calculateOperationalProjection(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _hppData!.estimasiPorsi,
      estimasiProduksiBulanan: _hppData!.estimasiProduksiBulanan,
    );
  }

  // HELPER METHODS
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

    if (_hppData != null) {
      _hppData = _hppData!.copyWith(
        karyawan: _karyawan,
        totalOperationalCost: 0.0,
        totalHargaSetelahOperational: _hppData!.hppMurniPerPorsi,
      );
    }

    _scheduleAutoSave();
    notifyListeners();
  }

  // UTILITY GETTERS - FIXED: With division by zero protection
  double get totalGajiBulanan {
    return OperationalCalculatorService.calculateTotalGajiBulanan(_karyawan);
  }

  double get operationalCostPerPorsi {
    if (_hppData == null ||
        _hppData!.estimasiPorsi <= 0 ||
        _hppData!.estimasiProduksiBulanan <= 0) {
      return 0.0;
    }

    return OperationalCalculatorService.calculateOperationalCostPerPorsi(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _hppData!.estimasiPorsi,
      estimasiProduksiBulanan: _hppData!.estimasiProduksiBulanan,
    );
  }

  String get formattedTotalGaji {
    return OperationalCalculatorService.formatRupiah(totalGajiBulanan);
  }

  String get formattedOperationalPerPorsi {
    return OperationalCalculatorService.formatRupiah(operationalCostPerPorsi);
  }

  bool get hasKaryawan => _karyawan.isNotEmpty;
  bool get isCalculationReady => _karyawan.isNotEmpty && _hppData != null;
  int get karyawanCount => _karyawan.length;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
