// lib/providers/hpp_provider.dart
import 'package:flutter/foundation.dart';
import '../models/shared_calculation_data.dart';
import '../services/hpp_calculator_service.dart';

class HPPProvider with ChangeNotifier {
  SharedCalculationData _data = SharedCalculationData();
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  SharedCalculationData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> updateVariableCosts(List<Map<String, dynamic>> costs) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = SharedCalculationData(
        variableCosts: costs,
        fixedCosts: _data.fixedCosts,
        estimasiPorsi: _data.estimasiPorsi,
        estimasiProduksiBulanan: _data.estimasiProduksiBulanan,
        karyawan: _data.karyawan,
      );

      await _recalculateHPP();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _recalculateHPP() async {
    final result = HPPCalculatorService.calculateHPP(
      variableCosts: _data.variableCosts,
      fixedCosts: _data.fixedCosts,
      estimasiPorsiPerProduksi: _data.estimasiPorsi,
      estimasiProduksiBulanan: _data.estimasiProduksiBulanan,
    );

    if (!result.isValid) {
      throw Exception(result.errorMessage);
    }

    _data = SharedCalculationData(
      variableCosts: _data.variableCosts,
      fixedCosts: _data.fixedCosts,
      estimasiPorsi: _data.estimasiPorsi,
      estimasiProduksiBulanan: _data.estimasiProduksiBulanan,
      hppMurniPerPorsi: result.hppMurniPerPorsi,
      biayaVariablePerPorsi: result.biayaVariablePerPorsi,
      biayaFixedPerPorsi: result.biayaFixedPerPorsi,
      karyawan: _data.karyawan,
    );
  }

  void addVariableCost(
      String nama, double totalHarga, double jumlah, String satuan) {
    if (nama.trim().isEmpty || totalHarga <= 0 || jumlah <= 0) {
      _errorMessage = 'Data tidak valid';
      notifyListeners();
      return;
    }

    final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
    newCosts.add({
      'nama': nama.trim(),
      'totalHarga': totalHarga,
      'jumlah': jumlah,
      'satuan': satuan,
    });

    updateVariableCosts(newCosts);
  }

  void removeVariableCost(int index) {
    if (index < 0 || index >= _data.variableCosts.length) return;

    final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
    newCosts.removeAt(index);
    updateVariableCosts(newCosts);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
