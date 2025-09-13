import 'package:flutter/foundation.dart';
import '../models/shared_calculation_data.dart';
import '../services/hpp_calculator_service.dart';
import '../utils/validators.dart';

class HPPProvider with ChangeNotifier {
  SharedCalculationData _data = SharedCalculationData();
  String? _errorMessage;
  bool _isLoading = false;
  HPPCalculationResult? _lastCalculationResult;

  // Getters
  SharedCalculationData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  HPPCalculationResult? get lastCalculationResult => _lastCalculationResult;

  // Variable Costs Methods
  Future<void> updateVariableCosts(List<Map<String, dynamic>> costs) async {
    _setLoading(true);
    try {
      _data = _data.copyWith(variableCosts: costs);
      await _recalculateHPP();
      _setError(null);
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

  // Fixed Costs Methods
  Future<void> updateFixedCosts(List<Map<String, dynamic>> costs) async {
    _setLoading(true);
    try {
      _data = _data.copyWith(fixedCosts: costs);
      await _recalculateHPP();
      _setError(null);
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

  // Estimation Methods
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
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Core calculation method
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
        throw Exception(result.errorMessage ?? 'Calculation failed');
      }
    } catch (e) {
      _lastCalculationResult = null;
      throw e;
    }
  }

  // Helper methods
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

  // Reset data
  void resetData() {
    _data = SharedCalculationData();
    _lastCalculationResult = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
