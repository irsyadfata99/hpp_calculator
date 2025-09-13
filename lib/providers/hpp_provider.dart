// lib/providers/hpp_provider.dart - COMPLETE IMPLEMENTATION
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/shared_calculation_data.dart';
import '../services/hpp_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

class HPPProvider with ChangeNotifier {
  SharedCalculationData _data = SharedCalculationData();
  String? _errorMessage;
  bool _isLoading = false;
  HPPCalculationResult? _lastCalculationResult;

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Getters
  SharedCalculationData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  HPPCalculationResult? get lastCalculationResult => _lastCalculationResult;

  // ===============================================
  // INITIALIZATION WITH STORAGE
  // ===============================================

  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _data = savedData;
        await _recalculateHPP();
        debugPrint(
            '✅ HPP Data loaded from storage: ${savedData.totalItemCount} items');
      } else {
        debugPrint('ℹ️ No saved HPP data found, using defaults');
      }
      _setError(null);
    } catch (e) {
      _setError('Error loading data: ${e.toString()}');
      debugPrint('❌ Error loading HPP from storage: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // VARIABLE COSTS METHODS - WITH AUTO SAVE
  // ===============================================

  Future<void> updateVariableCosts(List<Map<String, dynamic>> costs) async {
    _setLoading(true);
    try {
      _data = _data.copyWith(variableCosts: costs);
      await _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addVariableCost(
      String nama, double totalHarga, double jumlah, String satuan) async {
    // Validate input
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _setError('Nama: $namaValidation');
      return;
    }

    final hargaValidation = InputValidator.validatePrice(totalHarga.toString());
    if (hargaValidation != null) {
      _setError('Harga: $hargaValidation');
      return;
    }

    final jumlahValidation = InputValidator.validateQuantity(jumlah.toString());
    if (jumlahValidation != null) {
      _setError('Jumlah: $jumlahValidation');
      return;
    }

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
      newCosts.add({
        'nama': nama.trim(),
        'totalHarga': totalHarga,
        'jumlah': jumlah,
        'satuan': satuan,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await updateVariableCosts(newCosts);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> removeVariableCost(int index) async {
    if (index < 0 || index >= _data.variableCosts.length) return;

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
      newCosts.removeAt(index);
      await updateVariableCosts(newCosts);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // ===============================================
  // FIXED COSTS METHODS - WITH AUTO SAVE
  // ===============================================

  Future<void> updateFixedCosts(List<Map<String, dynamic>> costs) async {
    _setLoading(true);
    try {
      _data = _data.copyWith(fixedCosts: costs);
      await _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFixedCost(String jenis, double nominal) async {
    // Validate input
    final jenisValidation = InputValidator.validateName(jenis);
    if (jenisValidation != null) {
      _setError('Jenis: $jenisValidation');
      return;
    }

    final nominalValidation = InputValidator.validatePrice(nominal.toString());
    if (nominalValidation != null) {
      _setError('Nominal: $nominalValidation');
      return;
    }

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.fixedCosts);
      newCosts.add({
        'jenis': jenis.trim(),
        'nominal': nominal,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await updateFixedCosts(newCosts);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> removeFixedCost(int index) async {
    if (index < 0 || index >= _data.fixedCosts.length) return;

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.fixedCosts);
      newCosts.removeAt(index);
      await updateFixedCosts(newCosts);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // ===============================================
  // ESTIMATION METHODS - WITH AUTO SAVE
  // ===============================================

  Future<void> updateEstimasi(double porsi, double produksiBulanan) async {
    // Validate input
    final porsiValidation = InputValidator.validateQuantity(porsi.toString());
    if (porsiValidation != null) {
      _setError('Estimasi Porsi: $porsiValidation');
      return;
    }

    final produksiValidation =
        InputValidator.validateQuantity(produksiBulanan.toString());
    if (produksiValidation != null) {
      _setError('Estimasi Produksi: $produksiValidation');
      return;
    }

    _setLoading(true);
    try {
      _data = _data.copyWith(
        estimasiPorsi: porsi,
        estimasiProduksiBulanan: produksiBulanan,
      );
      await _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // CORE CALCULATION METHOD
  // ===============================================

  Future<void> _recalculateHPP() async {
    try {
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: _data.variableCosts,
        fixedCosts: _data.fixedCosts,
        estimasiPorsiPerProduksi: _data.estimasiPorsi,
        estimasiProduksiBulanan: _data.estimasiProduksiBulanan,
      );

      _lastCalculationResult = result;

      if (result.isValid) {
        _data = _data.copyWith(
          hppMurniPerPorsi: result.hppMurniPerPorsi,
          biayaVariablePerPorsi: result.biayaVariablePerPorsi,
          biayaFixedPerPorsi: result.biayaFixedPerPorsi,
        );
      } else {
        debugPrint('❌ HPP Calculation failed: ${result.errorMessage}');
        // Don't throw, just keep invalid result for display
      }
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ HPP Calculation error: $e');
      // Don't rethrow to avoid breaking the UI
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
    try {
      await StorageService.autoSave(_data);
      debugPrint('💾 HPP Auto-save completed: ${_data.totalItemCount} items');
    } catch (e) {
      debugPrint('❌ HPP Auto-save failed: $e');
      // Don't set error for auto-save failures to avoid UI disruption
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
        await initializeFromStorage(); // Reload data
        debugPrint('✅ HPP Data imported successfully');
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

  Future<void> clearAllData() async {
    try {
      _setLoading(true);
      await StorageService.clearAllData();
      _data = SharedCalculationData();
      _lastCalculationResult = null;
      _setError(null);
      debugPrint('🗑️ HPP Data cleared');
      notifyListeners();
    } catch (e) {
      _setError('Clear data failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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
    _data = SharedCalculationData();
    _lastCalculationResult = null;
    _errorMessage = null;
    _isLoading = false;
    _scheduleAutoSave(); // Save the reset state
    notifyListeners();
  }

  // ===============================================
  // ADDITIONAL UTILITY METHODS
  // ===============================================

  // Get formatted totals
  String get formattedTotalVariableCosts {
    return _data.formatRupiah(_data.totalVariableCosts);
  }

  String get formattedTotalFixedCosts {
    return _data.formatRupiah(_data.totalFixedCosts);
  }

  String get formattedHppMurni {
    return _data.formatRupiah(_data.hppMurniPerPorsi);
  }

  // Check if calculation is ready
  bool get isCalculationReady {
    return _data.variableCosts.isNotEmpty &&
        _data.estimasiPorsi > 0 &&
        _data.estimasiProduksiBulanan > 0;
  }

  // Get calculation summary
  Map<String, dynamic> get calculationSummary {
    return {
      'totalVariableItems': _data.variableCosts.length,
      'totalFixedItems': _data.fixedCosts.length,
      'totalItems': _data.totalItemCount,
      'isValid': _lastCalculationResult?.isValid ?? false,
      'hppMurni': _data.hppMurniPerPorsi,
      'lastCalculated': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
