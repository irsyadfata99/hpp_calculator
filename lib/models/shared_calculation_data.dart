// lib/models/shared_calculation_data.dart
import 'karyawan_data.dart';
import '../services/operational_calculator_service.dart';
import '../services/hpp_calculator_service.dart';

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
    this.estimasiPorsi = 1.0,
    this.estimasiProduksiBulanan = 30.0,
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

  // Format rupiah menggunakan service (consistency)
  String formatRupiah(double amount) {
    return HPPCalculatorService.formatRupiah(amount);
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
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
      estimasiPorsi: map['estimasiPorsi']?.toDouble() ?? 1.0,
      estimasiProduksiBulanan:
          map['estimasiProduksiBulanan']?.toDouble() ?? 30.0,
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
}
