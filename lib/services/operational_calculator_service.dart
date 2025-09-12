// File: lib/services/operational_calculator_service.dart

import '../models/karyawan_data.dart';

class OperationalCalculationResult {
  final double totalGajiBulanan;
  final double operationalCostPerPorsi;
  final double totalHargaSetelahOperational;
  final double totalPorsiBulanan;
  final int jumlahKaryawan;
  final bool isValid;
  final String? errorMessage;

  OperationalCalculationResult({
    required this.totalGajiBulanan,
    required this.operationalCostPerPorsi,
    required this.totalHargaSetelahOperational,
    required this.totalPorsiBulanan,
    required this.jumlahKaryawan,
    required this.isValid,
    this.errorMessage,
  });

  factory OperationalCalculationResult.error(String message) {
    return OperationalCalculationResult(
      totalGajiBulanan: 0.0,
      operationalCostPerPorsi: 0.0,
      totalHargaSetelahOperational: 0.0,
      totalPorsiBulanan: 0.0,
      jumlahKaryawan: 0,
      isValid: false,
      errorMessage: message,
    );
  }
}

class OperationalCalculatorService {
  /// Menghitung total biaya operational berdasarkan data karyawan
  ///
  /// Rumus: Total Gaji Bulanan = Σ(Gaji Karyawan)
  static double calculateTotalGajiBulanan(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return 0.0;

    return karyawan.fold(0.0, (sum, k) => sum + k.gajiBulanan);
  }

  /// Menghitung biaya operational per porsi
  ///
  /// Rumus: Operational Cost per Porsi = Total Gaji Bulanan ÷ Total Porsi Bulanan
  /// Di mana: Total Porsi Bulanan = Estimasi Porsi per Produksi × Estimasi Produksi per Bulan
  static double calculateOperationalCostPerPorsi({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    if (estimasiPorsiPerProduksi <= 0 || estimasiProduksiBulanan <= 0) {
      return 0.0;
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double totalPorsiBulanan =
        estimasiPorsiPerProduksi * estimasiProduksiBulanan;

    return totalGaji / totalPorsiBulanan;
  }

  /// Menghitung total harga final setelah termasuk biaya operational
  ///
  /// Rumus: Total Harga Akhir = HPP Murni + Biaya Operational per Porsi
  static double calculateTotalHargaSetelahOperational({
    required double hppMurniPerPorsi,
    required double operationalCostPerPorsi,
  }) {
    return hppMurniPerPorsi + operationalCostPerPorsi;
  }

  /// Perhitungan lengkap operational cost dengan validasi
  static OperationalCalculationResult calculateOperationalCost({
    required List<KaryawanData> karyawan,
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // Validasi input
      final validationResult = _validateInputs(
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      if (!validationResult.isValid) {
        return OperationalCalculationResult.error(
            validationResult.errorMessage!);
      }

      // Hitung total gaji bulanan
      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);

      // Hitung total porsi bulanan
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // Hitung operational cost per porsi
      double operationalCostPerPorsi = calculateOperationalCostPerPorsi(
        karyawan: karyawan,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Hitung total harga setelah operational
      double totalHargaSetelahOperational =
          calculateTotalHargaSetelahOperational(
        hppMurniPerPorsi: hppMurniPerPorsi,
        operationalCostPerPorsi: operationalCostPerPorsi,
      );

      return OperationalCalculationResult(
        totalGajiBulanan: totalGajiBulanan,
        operationalCostPerPorsi: operationalCostPerPorsi,
        totalHargaSetelahOperational: totalHargaSetelahOperational,
        totalPorsiBulanan: totalPorsiBulanan,
        jumlahKaryawan: karyawan.length,
        isValid: true,
      );
    } catch (e) {
      return OperationalCalculationResult.error(
          'Error dalam perhitungan operational: ${e.toString()}');
    }
  }

  /// Validasi input parameters
  static OperationalCalculationResult _validateInputs({
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    if (estimasiPorsiPerProduksi <= 0) {
      return OperationalCalculationResult.error(
          'Estimasi Porsi per Produksi harus lebih besar dari 0');
    }

    if (estimasiProduksiBulanan <= 0) {
      return OperationalCalculationResult.error(
          'Estimasi Produksi Bulanan harus lebih besar dari 0');
    }

    return OperationalCalculationResult(
      totalGajiBulanan: 0.0,
      operationalCostPerPorsi: 0.0,
      totalHargaSetelahOperational: 0.0,
      totalPorsiBulanan: 0.0,
      jumlahKaryawan: 0,
      isValid: true,
    );
  }

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    if (amount.isNaN || amount.isInfinite) {
      return 'Rp 0';
    }

    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Menghitung proyeksi operational bulanan
  static Map<String, dynamic> calculateOperationalProjection({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
    double totalPorsiBulanan =
        estimasiPorsiPerProduksi * estimasiProduksiBulanan;
    double operationalPerPorsi =
        totalPorsiBulanan > 0 ? totalGajiBulanan / totalPorsiBulanan : 0.0;
    double operationalPerHari =
        totalGajiBulanan / 30; // Asumsi 30 hari per bulan

    return {
      'totalGajiBulanan': totalGajiBulanan,
      'operationalPerPorsi': operationalPerPorsi,
      'operationalPerHari': operationalPerHari,
      'jumlahKaryawan': karyawan.length,
      'totalPorsiBulanan': totalPorsiBulanan,
    };
  }

  /// Analisis efisiensi karyawan
  static Map<String, dynamic> analyzeKaryawanEfficiency({
    required List<KaryawanData> karyawan,
    required double totalPorsiBulanan,
  }) {
    if (karyawan.isEmpty || totalPorsiBulanan <= 0) {
      return {
        'averageGajiPerKaryawan': 0.0,
        'costPerKaryawanPerPorsi': 0.0,
        'porsiPerKaryawan': 0.0,
        'efficiency': 'N/A',
      };
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double averageGajiPerKaryawan = totalGaji / karyawan.length;
    double costPerKaryawanPerPorsi =
        totalGaji / (karyawan.length * totalPorsiBulanan);
    double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

    String efficiency;
    if (porsiPerKaryawan >= 400) {
      efficiency = 'Sangat Efisien';
    } else if (porsiPerKaryawan >= 300) {
      efficiency = 'Efisien';
    } else if (porsiPerKaryawan >= 200) {
      efficiency = 'Cukup Efisien';
    } else {
      efficiency = 'Kurang Efisien';
    }

    return {
      'averageGajiPerKaryawan': averageGajiPerKaryawan,
      'costPerKaryawanPerPorsi': costPerKaryawanPerPorsi,
      'porsiPerKaryawan': porsiPerKaryawan,
      'efficiency': efficiency,
    };
  }

  /// Validasi data karyawan lengkap
  static bool isKaryawanDataComplete(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return false;

    return karyawan.every((k) =>
        k.namaKaryawan.isNotEmpty && k.jabatan.isNotEmpty && k.gajiBulanan > 0);
  }
}
