// lib/models/shared_calculation_data.dart - FIXED VERSION NULL SAFETY
import 'karyawan_data.dart';
import '../services/operational_calculator_service.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class SharedCalculationData {
  // Data dari HPP Calculator
  List<Map<String, dynamic>> variableCosts;
  List<Map<String, dynamic>> fixedCosts;
  double estimasiPorsi;
  double estimasiProduksiBulanan;
  double hppMurniPerPorsi;
  double biayaVariablePerPorsi;
  double biayaFixedPerPorsi;

  // Data dari Operational Calculator
  List<KaryawanData> karyawan;
  double totalOperationalCost;
  double totalHargaSetelahOperational;

  SharedCalculationData({
    this.variableCosts = const [],
    this.fixedCosts = const [],
    this.estimasiPorsi = AppConstants.defaultEstimasiPorsi,
    this.estimasiProduksiBulanan = AppConstants.defaultEstimasiProduksi,
    this.hppMurniPerPorsi = 0.0,
    this.biayaVariablePerPorsi = 0.0,
    this.biayaFixedPerPorsi = 0.0,
    this.karyawan = const [],
    this.totalOperationalCost = 0.0,
    this.totalHargaSetelahOperational = 0.0,
  });

  // Calculate total operational cost menggunakan service
  double calculateTotalOperationalCost() {
    return OperationalCalculatorService.calculateTotalGajiBulanan(karyawan);
  }

  // Calculate operational cost per porsi menggunakan service
  double calculateOperationalCostPerPorsi() {
    return OperationalCalculatorService.calculateOperationalCostPerPorsi(
      karyawan: karyawan,
      estimasiPorsiPerProduksi: estimasiPorsi,
      estimasiProduksiBulanan: estimasiProduksiBulanan,
    );
  }

  // Calculate final total price including operational menggunakan service
  double calculateTotalHargaSetelahOperational() {
    double operationalPerPorsi = calculateOperationalCostPerPorsi();
    return OperationalCalculatorService.calculateTotalHargaSetelahOperational(
      hppMurniPerPorsi: hppMurniPerPorsi,
      operationalCostPerPorsi: operationalPerPorsi,
    );
  }

  // Format rupiah menggunakan integrated formatter
  String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  // Format percentage menggunakan integrated formatter
  String formatPercentage(double percentage) {
    return AppFormatters.formatPercentage(percentage);
  }

  // Validation helpers menggunakan constants
  bool get isValidForCalculation {
    return variableCosts.isNotEmpty &&
        estimasiPorsi >= AppConstants.minQuantity &&
        estimasiProduksiBulanan >= AppConstants.minQuantity;
  }

  double get totalVariableCosts {
    return variableCosts.fold(
        0.0, (sum, item) => sum + _safeGetDouble(item['totalHarga'], 0.0));
  }

  double get totalFixedCosts {
    return fixedCosts.fold(
        0.0, (sum, item) => sum + _safeGetDouble(item['nominal'], 0.0));
  }

  int get totalItemCount {
    return variableCosts.length + fixedCosts.length + karyawan.length;
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'version': AppConstants.appVersion,
      'variableCosts': variableCosts,
      'fixedCosts': fixedCosts,
      'estimasiPorsi': estimasiPorsi,
      'estimasiProduksiBulanan': estimasiProduksiBulanan,
      'hppMurniPerPorsi': hppMurniPerPorsi,
      'biayaVariablePerPorsi': biayaVariablePerPorsi,
      'biayaFixedPerPorsi': biayaFixedPerPorsi,
      'karyawan': karyawan.map((k) => k.toMap()).toList(),
      'totalOperationalCost': totalOperationalCost,
      'totalHargaSetelahOperational': totalHargaSetelahOperational,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // FIXED: Enhanced fromMap with comprehensive null safety
  static SharedCalculationData fromMap(Map<String, dynamic> map) {
    List<KaryawanData> karyawan = [];

    try {
      if (map['karyawan'] != null && map['karyawan'] is List) {
        karyawan = (map['karyawan'] as List)
            .map((item) {
              try {
                return KaryawanData.fromMap(item as Map<String, dynamic>);
              } catch (e) {
                print('🚨 Error parsing karyawan item: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<KaryawanData>()
            .toList();
      }
    } catch (e) {
      print('🚨 Error parsing karyawan list: $e');
      karyawan = [];
    }

    return SharedCalculationData(
      variableCosts: _safeGetList(map['variableCosts']),
      fixedCosts: _safeGetList(map['fixedCosts']),
      estimasiPorsi: _safeConvertToDouble(
          map['estimasiPorsi'], AppConstants.defaultEstimasiPorsi),
      estimasiProduksiBulanan: _safeConvertToDouble(
          map['estimasiProduksiBulanan'], AppConstants.defaultEstimasiProduksi),
      hppMurniPerPorsi: _safeConvertToDouble(map['hppMurniPerPorsi'], 0.0),
      biayaVariablePerPorsi:
          _safeConvertToDouble(map['biayaVariablePerPorsi'], 0.0),
      biayaFixedPerPorsi: _safeConvertToDouble(map['biayaFixedPerPorsi'], 0.0),
      karyawan: karyawan,
      totalOperationalCost:
          _safeConvertToDouble(map['totalOperationalCost'], 0.0),
      totalHargaSetelahOperational:
          _safeConvertToDouble(map['totalHargaSetelahOperational'], 0.0),
    );
  }

  // FIXED: Enhanced safe conversion method with comprehensive checks
  static double _safeConvertToDouble(dynamic value, double defaultValue) {
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
        final parsed = double.tryParse(value.trim());
        return (parsed != null && parsed.isFinite) ? parsed : defaultValue;
      }
    } catch (e) {
      print('🚨 Error converting to double: $value -> $e');
    }

    return defaultValue;
  }

  // FIXED: Safe list getter
  static List<Map<String, dynamic>> _safeGetList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      try {
        return value.cast<Map<String, dynamic>>();
      } catch (e) {
        print('🚨 Error casting list: $e');
        return [];
      }
    }
    return [];
  }

  // FIXED: Safe double getter for map values
  static double _safeGetDouble(dynamic value, double defaultValue) {
    return _safeConvertToDouble(value, defaultValue);
  }

  // Create a copy with updated values - FIXED: Ensure all params are double
  SharedCalculationData copyWith({
    List<KaryawanData>? karyawan,
    List<Map<String, dynamic>>? variableCosts,
    List<Map<String, dynamic>>? fixedCosts,
    double? estimasiPorsi,
    double? estimasiProduksiBulanan,
    double? hppMurniPerPorsi,
    double? biayaVariablePerPorsi,
    double? biayaFixedPerPorsi,
    double? totalOperationalCost,
    double? totalHargaSetelahOperational,
  }) {
    return SharedCalculationData(
      variableCosts: variableCosts ?? this.variableCosts,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      estimasiPorsi: _safeConvertToDouble(estimasiPorsi, this.estimasiPorsi),
      estimasiProduksiBulanan: _safeConvertToDouble(
          estimasiProduksiBulanan, this.estimasiProduksiBulanan),
      hppMurniPerPorsi:
          _safeConvertToDouble(hppMurniPerPorsi, this.hppMurniPerPorsi),
      biayaVariablePerPorsi: _safeConvertToDouble(
          biayaVariablePerPorsi, this.biayaVariablePerPorsi),
      biayaFixedPerPorsi:
          _safeConvertToDouble(biayaFixedPerPorsi, this.biayaFixedPerPorsi),
      karyawan: karyawan ?? this.karyawan,
      totalOperationalCost:
          _safeConvertToDouble(totalOperationalCost, this.totalOperationalCost),
      totalHargaSetelahOperational: _safeConvertToDouble(
          totalHargaSetelahOperational, this.totalHargaSetelahOperational),
    );
  }

  // Update calculated values
  void updateCalculatedValues() {
    totalOperationalCost = calculateTotalOperationalCost();
    totalHargaSetelahOperational = calculateTotalHargaSetelahOperational();
  }

  // Reset to defaults menggunakan constants
  void reset() {
    variableCosts.clear();
    fixedCosts.clear();
    karyawan.clear();
    estimasiPorsi = AppConstants.defaultEstimasiPorsi;
    estimasiProduksiBulanan = AppConstants.defaultEstimasiProduksi;
    hppMurniPerPorsi = 0.0;
    biayaVariablePerPorsi = 0.0;
    biayaFixedPerPorsi = 0.0;
    totalOperationalCost = 0.0;
    totalHargaSetelahOperational = 0.0;
  }

  @override
  String toString() {
    return 'SharedCalculationData(items: $totalItemCount, hpp: ${formatRupiah(hppMurniPerPorsi)}, valid: $isValidForCalculation)';
  }
}
