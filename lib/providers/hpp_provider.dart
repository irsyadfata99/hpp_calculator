// lib/providers/hpp_provider.dart - PHASE 1 FIX: Root Provider (No Dependencies)
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
  Timer? _autoSaveTimer;

  // Getters
  SharedCalculationData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  HPPCalculationResult? get lastCalculationResult => _lastCalculationResult;

  // INITIALIZATION
  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _data = savedData;
        _recalculateHPP();
        debugPrint('✅ HPP Data loaded: ${savedData.totalItemCount} items');
      }
      _setError(null);
    } catch (e) {
      _setError('Error loading data: ${e.toString()}');
      debugPrint('❌ Error loading HPP: $e');
    } finally {
      _setLoading(false);
    }
  }

  // VARIABLE COSTS METHODS
  Future<void> addVariableCost(
      String nama, double totalHarga, double jumlah, String satuan) async {
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

      _data = _data.copyWith(variableCosts: newCosts);
      _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();

      // FIXED: Single notification - let ProxyProviders handle downstream updates
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeVariableCost(int index) async {
    if (index < 0 || index >= _data.variableCosts.length) return;

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
      newCosts.removeAt(index);

      _data = _data.copyWith(variableCosts: newCosts);
      _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();

      // FIXED: Single notification
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // FIXED COSTS METHODS
  Future<void> addFixedCost(String jenis, double nominal) async {
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

      _data = _data.copyWith(fixedCosts: newCosts);
      _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();

      // FIXED: Single notification
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFixedCost(int index) async {
    if (index < 0 || index >= _data.fixedCosts.length) return;

    _setLoading(true);
    try {
      final newCosts = List<Map<String, dynamic>>.from(_data.fixedCosts);
      newCosts.removeAt(index);

      _data = _data.copyWith(fixedCosts: newCosts);
      _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();

      // FIXED: Single notification
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ESTIMATION METHODS
  Future<void> updateEstimasi(double porsi, double produksiBulanan) async {
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

      _recalculateHPP();
      _setError(null);
      _scheduleAutoSave();

      // FIXED: Single notification
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // CORE CALCULATION - FIXED: Simple without anti-loop mechanisms
  void _recalculateHPP() {
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
      }
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ HPP Calculation error: $e');
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
    try {
      await StorageService.autoSave(_data);
      debugPrint('💾 HPP Auto-save completed');
    } catch (e) {
      debugPrint('❌ HPP Auto-save failed: $e');
    }
  }

  // HELPER METHODS
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) notifyListeners(); // Only notify when starting to load
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
    _scheduleAutoSave();
    notifyListeners();
  }

  // UTILITY GETTERS
  String get formattedTotalVariableCosts {
    return _data.formatRupiah(_data.totalVariableCosts);
  }

  String get formattedTotalFixedCosts {
    return _data.formatRupiah(_data.totalFixedCosts);
  }

  String get formattedHppMurni {
    return _data.formatRupiah(_data.hppMurniPerPorsi);
  }

  bool get isCalculationReady {
    return _data.variableCosts.isNotEmpty &&
        _data.estimasiPorsi > 0 &&
        _data.estimasiProduksiBulanan > 0;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
