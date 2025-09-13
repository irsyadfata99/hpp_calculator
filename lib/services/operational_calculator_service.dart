// File: lib/services/operational_calculator_service.dart (Full Integration)

import 'package:flutter/foundation.dart';
import '../models/karyawan_data.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

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

  factory OperationalCalculationResult.success({
    required double totalGajiBulanan,
    required double operationalCostPerPorsi,
    required double totalHargaSetelahOperational,
    required double totalPorsiBulanan,
    required int jumlahKaryawan,
  }) {
    return OperationalCalculationResult(
      totalGajiBulanan: totalGajiBulanan,
      operationalCostPerPorsi: operationalCostPerPorsi,
      totalHargaSetelahOperational: totalHargaSetelahOperational,
      totalPorsiBulanan: totalPorsiBulanan,
      jumlahKaryawan: jumlahKaryawan,
      isValid: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGajiBulanan': totalGajiBulanan,
      'operationalCostPerPorsi': operationalCostPerPorsi,
      'totalHargaSetelahOperational': totalHargaSetelahOperational,
      'totalPorsiBulanan': totalPorsiBulanan,
      'jumlahKaryawan': jumlahKaryawan,
      'isValid': isValid,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'OperationalCalculationResult(valid: $isValid, karyawan: $jumlahKaryawan, total: ${AppFormatters.formatRupiah(totalGajiBulanan)})';
  }
}

class OperationalCalculatorService {
  /// Menghitung total biaya operational berdasarkan data karyawan dengan full validation
  static double calculateTotalGajiBulanan(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return 0.0;

    double total = 0.0;
    for (var k in karyawan) {
      // Validate salary using integrated validator
      final salaryValidation =
          InputValidator.validateSalary(k.gajiBulanan.toString());
      if (salaryValidation != null) {
        debugPrint(
            'Warning: Gaji karyawan ${k.namaKaryawan} tidak valid: $salaryValidation');
        continue;
      }

      // Check against constants
      if (k.gajiBulanan > AppConstants.maxPrice) {
        debugPrint(
            'Warning: Gaji karyawan ${k.namaKaryawan} terlalu besar: ${k.gajiBulanan}');
        continue;
      }

      total += k.gajiBulanan;
    }

    return total;
  }

  /// Menghitung biaya operational per porsi dengan validation
  static double calculateOperationalCostPerPorsi({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // Validate inputs using integrated validators
    final porsiValidation =
        InputValidator.validateQuantity(estimasiPorsiPerProduksi.toString());
    if (porsiValidation != null) {
      debugPrint('Warning: Estimasi porsi tidak valid: $porsiValidation');
      return 0.0;
    }

    final produksiValidation =
        InputValidator.validateQuantity(estimasiProduksiBulanan.toString());
    if (produksiValidation != null) {
      debugPrint('Warning: Estimasi produksi tidak valid: $produksiValidation');
      return 0.0;
    }

    // Check against constants
    if (estimasiPorsiPerProduksi < AppConstants.minQuantity ||
        estimasiProduksiBulanan < AppConstants.minQuantity) {
      return 0.0;
    }

    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity ||
        estimasiProduksiBulanan > AppConstants.maxQuantity) {
      debugPrint(
          'Warning: Estimasi melebihi batas maksimal (${AppConstants.maxQuantity})');
      return 0.0;
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double totalPorsiBulanan =
        estimasiPorsiPerProduksi * estimasiProduksiBulanan;

    // Validate result
    if (totalPorsiBulanan <= 0) return 0.0;

    double result = totalGaji / totalPorsiBulanan;

    // Check if result is reasonable
    if (result > AppConstants.maxPrice) {
      debugPrint('Warning: Biaya operational per porsi terlalu besar: $result');
      return 0.0;
    }

    return result;
  }

  /// Menghitung total harga final setelah termasuk biaya operational
  static double calculateTotalHargaSetelahOperational({
    required double hppMurniPerPorsi,
    required double operationalCostPerPorsi,
  }) {
    // Validate inputs
    if (hppMurniPerPorsi < 0 || operationalCostPerPorsi < 0) {
      return 0.0;
    }

    double total = hppMurniPerPorsi + operationalCostPerPorsi;

    // Validate result against constants
    if (total > AppConstants.maxPrice) {
      debugPrint(
          'Warning: Total harga setelah operational terlalu besar: $total');
      return AppConstants.maxPrice;
    }

    return total;
  }

  /// Perhitungan lengkap operational cost dengan comprehensive validation
  static OperationalCalculationResult calculateOperationalCost({
    required List<KaryawanData> karyawan,
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // Validasi karyawan data
      final karyawanValidation = _validateKaryawanData(karyawan);
      if (!karyawanValidation.isValid) {
        return karyawanValidation;
      }

      // Validasi input parameters menggunakan integrated validators
      final inputValidation = _validateInputParameters(
        hppMurniPerPorsi: hppMurniPerPorsi,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      if (!inputValidation.isValid) {
        return inputValidation;
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

      return OperationalCalculationResult.success(
        totalGajiBulanan: totalGajiBulanan,
        operationalCostPerPorsi: operationalCostPerPorsi,
        totalHargaSetelahOperational: totalHargaSetelahOperational,
        totalPorsiBulanan: totalPorsiBulanan,
        jumlahKaryawan: karyawan.length,
      );
    } catch (e) {
      return OperationalCalculationResult.error(
          'Error dalam perhitungan operational: ${e.toString()}');
    }
  }

  /// Validasi comprehensive data karyawan
  static OperationalCalculationResult _validateKaryawanData(
      List<KaryawanData> karyawan) {
    // Karyawan boleh kosong, tapi kalau ada harus valid
    for (int i = 0; i < karyawan.length; i++) {
      final k = karyawan[i];

      // Validasi nama
      final namaValidation = InputValidator.validateName(k.namaKaryawan);
      if (namaValidation != null) {
        return OperationalCalculationResult.error(
            'Karyawan ke-${i + 1}: $namaValidation');
      }

      // Validasi jabatan
      final jabatanValidation = InputValidator.validateName(k.jabatan);
      if (jabatanValidation != null) {
        return OperationalCalculationResult.error(
            'Jabatan karyawan "${k.namaKaryawan}": $jabatanValidation');
      }

      // Validasi gaji
      final salaryValidation =
          InputValidator.validateSalary(k.gajiBulanan.toString());
      if (salaryValidation != null) {
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}": $salaryValidation');
      }

      // Check reasonable salary range
      if (k.gajiBulanan < 100000) {
        // Minimum wage check
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}" terlalu rendah (minimal Rp 100.000)');
      }
    }

    return OperationalCalculationResult.success(
      totalGajiBulanan: 0.0,
      operationalCostPerPorsi: 0.0,
      totalHargaSetelahOperational: 0.0,
      totalPorsiBulanan: 0.0,
      jumlahKaryawan: karyawan.length,
    );
  }

  /// Validasi input parameters menggunakan integrated validators
  static OperationalCalculationResult _validateInputParameters({
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // Validasi HPP
    if (hppMurniPerPorsi < 0) {
      return OperationalCalculationResult.error(
          'HPP murni tidak boleh negatif');
    }

    if (hppMurniPerPorsi > AppConstants.maxPrice) {
      return OperationalCalculationResult.error('HPP murni terlalu besar');
    }

    // Validasi estimasi porsi
    final porsiValidation =
        InputValidator.validateQuantity(estimasiPorsiPerProduksi.toString());
    if (porsiValidation != null) {
      return OperationalCalculationResult.error(
          'Estimasi Porsi: $porsiValidation');
    }

    // Validasi estimasi produksi
    final produksiValidation =
        InputValidator.validateQuantity(estimasiProduksiBulanan.toString());
    if (produksiValidation != null) {
      return OperationalCalculationResult.error(
          'Estimasi Produksi: $produksiValidation');
    }

    // Check against constants
    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity) {
      return OperationalCalculationResult.error(
          'Estimasi porsi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    if (estimasiProduksiBulanan > AppConstants.maxQuantity) {
      return OperationalCalculationResult.error(
          'Estimasi produksi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    return OperationalCalculationResult.success(
      totalGajiBulanan: 0.0,
      operationalCostPerPorsi: 0.0,
      totalHargaSetelahOperational: 0.0,
      totalPorsiBulanan: 0.0,
      jumlahKaryawan: 0,
    );
  }

  /// Format rupiah untuk display menggunakan integrated formatter
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// Menghitung proyeksi operational bulanan dengan analysis
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
    double averageGajiPerKaryawan =
        karyawan.isNotEmpty ? totalGajiBulanan / karyawan.length : 0.0;

    return {
      'totalGajiBulanan': totalGajiBulanan,
      'operationalPerPorsi': operationalPerPorsi,
      'operationalPerHari': operationalPerHari,
      'jumlahKaryawan': karyawan.length,
      'totalPorsiBulanan': totalPorsiBulanan,
      'averageGajiPerKaryawan': averageGajiPerKaryawan,
      'isEfficient': _analyzeEfficiency(karyawan, totalPorsiBulanan),
      'monthlyBreakdown': _calculateMonthlyBreakdown(karyawan),
    };
  }

  /// Analisis efisiensi karyawan dengan detailed metrics
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
        'recommendation': 'Tidak ada data karyawan',
      };
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double averageGajiPerKaryawan = totalGaji / karyawan.length;
    double costPerKaryawanPerPorsi =
        totalGaji / (karyawan.length * totalPorsiBulanan);
    double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

    String efficiency = _getEfficiencyLevel(porsiPerKaryawan);
    String recommendation =
        _getEfficiencyRecommendation(porsiPerKaryawan, karyawan.length);

    return {
      'averageGajiPerKaryawan': averageGajiPerKaryawan,
      'costPerKaryawanPerPorsi': costPerKaryawanPerPorsi,
      'porsiPerKaryawan': porsiPerKaryawan,
      'efficiency': efficiency,
      'recommendation': recommendation,
      'totalCost': totalGaji,
      'karyawanCount': karyawan.length,
    };
  }

  /// Helper untuk menganalisis efisiensi
  static bool _analyzeEfficiency(
      List<KaryawanData> karyawan, double totalPorsiBulanan) {
    if (karyawan.isEmpty) return true;

    double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;
    return porsiPerKaryawan >=
        200; // Target minimum 200 porsi per karyawan per bulan
  }

  /// Helper untuk level efisiensi
  static String _getEfficiencyLevel(double porsiPerKaryawan) {
    if (porsiPerKaryawan >= 400) return 'Sangat Efisien';
    if (porsiPerKaryawan >= 300) return 'Efisien';
    if (porsiPerKaryawan >= 200) return 'Cukup Efisien';
    if (porsiPerKaryawan >= 100) return 'Kurang Efisien';
    return 'Tidak Efisien';
  }

  /// Helper untuk rekomendasi efisiensi
  static String _getEfficiencyRecommendation(
      double porsiPerKaryawan, int jumlahKaryawan) {
    if (porsiPerKaryawan >= 400) {
      return 'Produktivitas sangat baik. Pertimbangkan ekspansi produksi.';
    } else if (porsiPerKaryawan >= 300) {
      return 'Produktivitas baik. Monitor konsistensi performa.';
    } else if (porsiPerKaryawan >= 200) {
      return 'Produktivitas cukup. Evaluasi proses kerja untuk optimasi.';
    } else if (porsiPerKaryawan >= 100) {
      return 'Produktivitas rendah. Perlu training atau penyesuaian workflow.';
    } else {
      return 'Produktivitas sangat rendah. Evaluasi ulang kebutuhan karyawan.';
    }
  }

  /// Helper untuk breakdown bulanan
  static Map<String, double> _calculateMonthlyBreakdown(
      List<KaryawanData> karyawan) {
    double totalGaji = calculateTotalGajiBulanan(karyawan);

    return {
      'week1': totalGaji * 0.25,
      'week2': totalGaji * 0.25,
      'week3': totalGaji * 0.25,
      'week4': totalGaji * 0.25,
      'total': totalGaji,
    };
  }

  /// Validasi data karyawan lengkap menggunakan integrated validators
  static bool isKaryawanDataComplete(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return false;

    return karyawan.every((k) {
      final namaValid = InputValidator.validateName(k.namaKaryawan) == null;
      final jabatanValid = InputValidator.validateName(k.jabatan) == null;
      final gajiValid =
          InputValidator.validateSalary(k.gajiBulanan.toString()) == null;

      return namaValid && jabatanValid && gajiValid;
    });
  }

  /// Estimate required staff berdasarkan target produksi
  static Map<String, dynamic> estimateRequiredStaff({
    required double targetPorsiBulanan,
    required double averageProductivityPerStaff,
  }) {
    if (averageProductivityPerStaff <= 0) {
      return {
        'requiredStaff': 0,
        'recommendation': 'Tidak dapat menghitung tanpa data produktivitas',
        'isRealistic': false,
      };
    }

    int requiredStaff =
        (targetPorsiBulanan / averageProductivityPerStaff).ceil();
    bool isRealistic = requiredStaff <= 50; // Reasonable limit

    String recommendation;
    if (requiredStaff <= 5) {
      recommendation = 'Tim kecil, cocok untuk UMKM startup';
    } else if (requiredStaff <= 15) {
      recommendation = 'Tim sedang, butuh manajemen yang baik';
    } else if (requiredStaff <= 30) {
      recommendation = 'Tim besar, butuh struktur organisasi yang jelas';
    } else {
      recommendation =
          'Tim sangat besar, pertimbangkan otomasi atau pembagian shift';
    }

    return {
      'requiredStaff': requiredStaff,
      'recommendation': recommendation,
      'isRealistic': isRealistic,
      'targetPorsiBulanan': targetPorsiBulanan,
      'productivityPerStaff': averageProductivityPerStaff,
    };
  }
}
