// lib/models/shared_calculation_data.dart - FIXED VERSION
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
        0.0, (sum, item) => sum + (item['totalHarga'] ?? 0.0));
  }

  double get totalFixedCosts {
    return fixedCosts.fold(0.0, (sum, item) => sum + (item['nominal'] ?? 0.0));
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

  // FIXED: Better type conversion with explicit double casting
  static SharedCalculationData fromMap(Map<String, dynamic> map) {
    List<KaryawanData> karyawan = (map['karyawan'] as List?)
            ?.map((item) => KaryawanData.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SharedCalculationData(
      variableCosts:
          List<Map<String, dynamic>>.from(map['variableCosts'] ?? []),
      fixedCosts: List<Map<String, dynamic>>.from(map['fixedCosts'] ?? []),
      estimasiPorsi: _safeConvertToDouble(map['estimasiPorsi']) ??
          AppConstants.defaultEstimasiPorsi,
      estimasiProduksiBulanan:
          _safeConvertToDouble(map['estimasiProduksiBulanan']) ??
              AppConstants.defaultEstimasiProduksi,
      hppMurniPerPorsi: _safeConvertToDouble(map['hppMurniPerPorsi']) ?? 0.0,
      biayaVariablePerPorsi:
          _safeConvertToDouble(map['biayaVariablePerPorsi']) ?? 0.0,
      biayaFixedPerPorsi:
          _safeConvertToDouble(map['biayaFixedPerPorsi']) ?? 0.0,
      karyawan: karyawan,
      totalOperationalCost:
          _safeConvertToDouble(map['totalOperationalCost']) ?? 0.0,
      totalHargaSetelahOperational:
          _safeConvertToDouble(map['totalHargaSetelahOperational']) ?? 0.0,
    );
  }

  // FIXED: Safe conversion method to handle int/double conversion
  static double? _safeConvertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Create a copy with updated values - FIXED: Ensure all params are double
  SharedCalculationData copyWith({
    List<Map<String, dynamic>>? variableCosts,
    List<Map<String, dynamic>>? fixedCosts,
    double? estimasiPorsi,
    double? estimasiProduksiBulanan,
    double? hppMurniPerPorsi,
    double? biayaVariablePerPorsi,
    double? biayaFixedPerPorsi,
    List<KaryawanData>? karyawan,
    double? totalOperationalCost,
    double? totalHargaSetelahOperational,
  }) {
    // FIXED: Ensure double type conversion
    return SharedCalculationData(
      variableCosts: variableCosts ?? this.variableCosts,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      estimasiPorsi: estimasiPorsi?.toDouble() ?? this.estimasiPorsi,
      estimasiProduksiBulanan:
          estimasiProduksiBulanan?.toDouble() ?? this.estimasiProduksiBulanan,
      hppMurniPerPorsi: hppMurniPerPorsi?.toDouble() ?? this.hppMurniPerPorsi,
      biayaVariablePerPorsi:
          biayaVariablePerPorsi?.toDouble() ?? this.biayaVariablePerPorsi,
      biayaFixedPerPorsi:
          biayaFixedPerPorsi?.toDouble() ?? this.biayaFixedPerPorsi,
      karyawan: karyawan ?? this.karyawan,
      totalOperationalCost:
          totalOperationalCost?.toDouble() ?? this.totalOperationalCost,
      totalHargaSetelahOperational: totalHargaSetelahOperational?.toDouble() ??
          this.totalHargaSetelahOperational,
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
