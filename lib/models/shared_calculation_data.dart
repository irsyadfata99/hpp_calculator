// lib/models/shared_calculation_data.dart (Full Integration)
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
    this.estimasiPorsi = AppConstants.defaultEstimasiPorsi, // Using constants
    this.estimasiProduksiBulanan =
        AppConstants.defaultEstimasiProduksi, // Using constants
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
      'version': AppConstants.appVersion, // Using constants
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

  // Create from Map for JSON deserialization
  static SharedCalculationData fromMap(Map<String, dynamic> map) {
    List<KaryawanData> karyawan = (map['karyawan'] as List?)
            ?.map((item) => KaryawanData.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SharedCalculationData(
      variableCosts:
          List<Map<String, dynamic>>.from(map['variableCosts'] ?? []),
      fixedCosts: List<Map<String, dynamic>>.from(map['fixedCosts'] ?? []),
      estimasiPorsi:
          map['estimasiPorsi']?.toDouble() ?? AppConstants.defaultEstimasiPorsi,
      estimasiProduksiBulanan: map['estimasiProduksiBulanan']?.toDouble() ??
          AppConstants.defaultEstimasiProduksi,
      hppMurniPerPorsi: map['hppMurniPerPorsi']?.toDouble() ?? 0.0,
      biayaVariablePerPorsi: map['biayaVariablePerPorsi']?.toDouble() ?? 0.0,
      biayaFixedPerPorsi: map['biayaFixedPerPorsi']?.toDouble() ?? 0.0,
      karyawan: karyawan,
      totalOperationalCost: map['totalOperationalCost']?.toDouble() ?? 0.0,
      totalHargaSetelahOperational:
          map['totalHargaSetelahOperational']?.toDouble() ?? 0.0,
    );
  }

  // Create a copy with updated values
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
    return SharedCalculationData(
      variableCosts: variableCosts ?? this.variableCosts,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      estimasiPorsi: estimasiPorsi ?? this.estimasiPorsi,
      estimasiProduksiBulanan:
          estimasiProduksiBulanan ?? this.estimasiProduksiBulanan,
      hppMurniPerPorsi: hppMurniPerPorsi ?? this.hppMurniPerPorsi,
      biayaVariablePerPorsi:
          biayaVariablePerPorsi ?? this.biayaVariablePerPorsi,
      biayaFixedPerPorsi: biayaFixedPerPorsi ?? this.biayaFixedPerPorsi,
      karyawan: karyawan ?? this.karyawan,
      totalOperationalCost: totalOperationalCost ?? this.totalOperationalCost,
      totalHargaSetelahOperational:
          totalHargaSetelahOperational ?? this.totalHargaSetelahOperational,
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
