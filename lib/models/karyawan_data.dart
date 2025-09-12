// File: lib/models/karyawan_data.dart

// Import statements harus di bagian atas sebelum deklarasi apapun
import '../services/operational_calculator_service.dart';
import '../services/hpp_calculator_service.dart';

// models/karyawan_data.dart
class KaryawanData {
  final String id;
  final String namaKaryawan;
  final String jabatan;
  final double gajiBulanan;
  final DateTime createdAt;

  KaryawanData({
    required this.id,
    required this.namaKaryawan,
    required this.jabatan,
    required this.gajiBulanan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_karyawan': namaKaryawan,
      'jabatan': jabatan,
      'gaji_bulanan': gajiBulanan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KaryawanData.fromMap(Map<String, dynamic> map) {
    return KaryawanData(
      id: map['id'],
      namaKaryawan: map['nama_karyawan'],
      jabatan: map['jabatan'],
      gajiBulanan: map['gaji_bulanan'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// models/shared_data.dart
// Updated: Menggunakan service untuk perhitungan

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
}
