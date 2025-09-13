// File: lib/services/operational_calculator_service.dart - FIXED TYPE CONVERSION

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
  /// FIXED: Menghitung total biaya operational dengan explicit double conversion
  static double calculateTotalGajiBulanan(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return 0.0;

    double total = 0.0;
    for (var k in karyawan) {
      // FIXED: Explicit double conversion
      double gaji = k.gajiBulanan.toDouble();

      // Validate salary using integrated validator
      final salaryValidation = InputValidator.validateSalary(gaji.toString());
      if (salaryValidation != null) {
        debugPrint(
            'Warning: Gaji karyawan ${k.namaKaryawan} tidak valid: $salaryValidation');
        continue;
      }

      // Check against constants
      if (gaji > AppConstants.maxPrice) {
        debugPrint(
            'Warning: Gaji karyawan ${k.namaKaryawan} terlalu besar: $gaji');
        continue;
      }

      total += gaji;
    }

    debugPrint(
        '✅ Total gaji calculated: ${AppFormatters.formatRupiah(total)} from ${karyawan.length} employees');
    return total;
  }

  /// FIXED: Menghitung biaya operational per porsi dengan explicit type conversion
  static double calculateOperationalCostPerPorsi({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    debugPrint('🧮 calculateOperationalCostPerPorsi called with:');
    debugPrint(
        '  estimasiPorsiPerProduksi: $estimasiPorsiPerProduksi (${estimasiPorsiPerProduksi.runtimeType})');
    debugPrint(
        '  estimasiProduksiBulanan: $estimasiProduksiBulanan (${estimasiProduksiBulanan.runtimeType})');
    debugPrint('  karyawan count: ${karyawan.length}');

    // FIXED: Explicit double conversion
    double porsi = estimasiPorsiPerProduksi.toDouble();
    double produksi = estimasiProduksiBulanan.toDouble();

    // Validate inputs using integrated validators
    final porsiValidation = InputValidator.validateQuantity(porsi.toString());
    if (porsiValidation != null) {
      debugPrint('❌ Warning: Estimasi porsi tidak valid: $porsiValidation');
      return 0.0;
    }

    final produksiValidation =
        InputValidator.validateQuantity(produksi.toString());
    if (produksiValidation != null) {
      debugPrint(
          '❌ Warning: Estimasi produksi tidak valid: $produksiValidation');
      return 0.0;
    }

    // Check against constants
    if (porsi < AppConstants.minQuantity ||
        produksi < AppConstants.minQuantity) {
      debugPrint(
          '❌ Warning: Estimasi kurang dari minimum (${AppConstants.minQuantity})');
      return 0.0;
    }

    if (porsi > AppConstants.maxQuantity ||
        produksi > AppConstants.maxQuantity) {
      debugPrint(
          '❌ Warning: Estimasi melebihi batas maksimal (${AppConstants.maxQuantity})');
      return 0.0;
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double totalPorsiBulanan = porsi * produksi;

    debugPrint('💰 Calculation details:');
    debugPrint('  totalGaji: ${AppFormatters.formatRupiah(totalGaji)}');
    debugPrint('  totalPorsiBulanan: $totalPorsiBulanan porsi');

    // Validate result
    if (totalPorsiBulanan <= 0) {
      debugPrint('❌ Warning: Total porsi bulanan zero or negative');
      return 0.0;
    }

    double result = totalGaji / totalPorsiBulanan;

    // Check if result is reasonable
    if (result > AppConstants.maxPrice) {
      debugPrint(
          '❌ Warning: Biaya operational per porsi terlalu besar: ${AppFormatters.formatRupiah(result)}');
      return 0.0;
    }

    debugPrint(
        '✅ Operational cost per porsi: ${AppFormatters.formatRupiah(result)}');
    return result;
  }

  /// FIXED: Menghitung total harga final dengan explicit double conversion
  static double calculateTotalHargaSetelahOperational({
    required double hppMurniPerPorsi,
    required double operationalCostPerPorsi,
  }) {
    // FIXED: Explicit double conversion
    double hpp = hppMurniPerPorsi.toDouble();
    double operational = operationalCostPerPorsi.toDouble();

    debugPrint('🏁 calculateTotalHargaSetelahOperational:');
    debugPrint('  hppMurniPerPorsi: ${AppFormatters.formatRupiah(hpp)}');
    debugPrint(
        '  operationalCostPerPorsi: ${AppFormatters.formatRupiah(operational)}');

    // Validate inputs
    if (hpp < 0 || operational < 0) {
      debugPrint('❌ Warning: Negative values detected');
      return 0.0;
    }

    double total = hpp + operational;

    // Validate result against constants
    if (total > AppConstants.maxPrice) {
      debugPrint(
          '❌ Warning: Total harga setelah operational terlalu besar: ${AppFormatters.formatRupiah(total)}');
      return AppConstants.maxPrice;
    }

    debugPrint(
        '✅ Total harga setelah operational: ${AppFormatters.formatRupiah(total)}');
    return total;
  }

  /// FIXED: Perhitungan lengkap operational cost dengan comprehensive validation dan type conversion
  static OperationalCalculationResult calculateOperationalCost({
    required List<KaryawanData> karyawan,
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    debugPrint(
        '🚀 OperationalCalculatorService.calculateOperationalCost called');
    debugPrint('📊 Input parameters:');
    debugPrint(
        '  hppMurniPerPorsi: $hppMurniPerPorsi (${hppMurniPerPorsi.runtimeType})');
    debugPrint(
        '  estimasiPorsiPerProduksi: $estimasiPorsiPerProduksi (${estimasiPorsiPerProduksi.runtimeType})');
    debugPrint(
        '  estimasiProduksiBulanan: $estimasiProduksiBulanan (${estimasiProduksiBulanan.runtimeType})');
    debugPrint('  karyawan count: ${karyawan.length}');

    try {
      // FIXED: Explicit double conversion for all parameters
      double hpp = hppMurniPerPorsi.toDouble();
      double porsi = estimasiPorsiPerProduksi.toDouble();
      double produksi = estimasiProduksiBulanan.toDouble();

      debugPrint('🔄 After type conversion:');
      debugPrint('  hpp: $hpp (${hpp.runtimeType})');
      debugPrint('  porsi: $porsi (${porsi.runtimeType})');
      debugPrint('  produksi: $produksi (${produksi.runtimeType})');

      // Validasi karyawan data
      final karyawanValidation = _validateKaryawanData(karyawan);
      if (!karyawanValidation.isValid) {
        debugPrint(
            '❌ Karyawan validation failed: ${karyawanValidation.errorMessage}');
        return karyawanValidation;
      }

      // Validasi input parameters menggunakan integrated validators
      final inputValidation = _validateInputParameters(
        hppMurniPerPorsi: hpp,
        estimasiPorsiPerProduksi: porsi,
        estimasiProduksiBulanan: produksi,
      );

      if (!inputValidation.isValid) {
        debugPrint(
            '❌ Input validation failed: ${inputValidation.errorMessage}');
        return inputValidation;
      }

      // Hitung total gaji bulanan
      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);

      // Hitung total porsi bulanan
      double totalPorsiBulanan = porsi * produksi;

      // Hitung operational cost per porsi
      double operationalCostPerPorsi = calculateOperationalCostPerPorsi(
        karyawan: karyawan,
        estimasiPorsiPerProduksi: porsi,
        estimasiProduksiBulanan: produksi,
      );

      // Hitung total harga setelah operational
      double totalHargaSetelahOperational =
          calculateTotalHargaSetelahOperational(
        hppMurniPerPorsi: hpp,
        operationalCostPerPorsi: operationalCostPerPorsi,
      );

      debugPrint('✅ Calculation results:');
      debugPrint(
          '  totalGajiBulanan: ${AppFormatters.formatRupiah(totalGajiBulanan)}');
      debugPrint(
          '  operationalCostPerPorsi: ${AppFormatters.formatRupiah(operationalCostPerPorsi)}');
      debugPrint(
          '  totalHargaSetelahOperational: ${AppFormatters.formatRupiah(totalHargaSetelahOperational)}');
      debugPrint('  totalPorsiBulanan: $totalPorsiBulanan');

      return OperationalCalculationResult.success(
        totalGajiBulanan: totalGajiBulanan,
        operationalCostPerPorsi: operationalCostPerPorsi,
        totalHargaSetelahOperational: totalHargaSetelahOperational,
        totalPorsiBulanan: totalPorsiBulanan,
        jumlahKaryawan: karyawan.length,
      );
    } catch (e) {
      debugPrint('❌ Error dalam perhitungan operational: $e');
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

      // Validasi gaji dengan explicit conversion
      double gaji = k.gajiBulanan.toDouble();
      final salaryValidation = InputValidator.validateSalary(gaji.toString());
      if (salaryValidation != null) {
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}": $salaryValidation');
      }

      // Check reasonable salary range
      if (gaji < 100000) {
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

  /// FIXED: Validasi input parameters dengan explicit double conversion
  static OperationalCalculationResult _validateInputParameters({
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // FIXED: Explicit double conversion
    double hpp = hppMurniPerPorsi.toDouble();
    double porsi = estimasiPorsiPerProduksi.toDouble();
    double produksi = estimasiProduksiBulanan.toDouble();

    // Validasi HPP
    if (hpp < 0) {
      return OperationalCalculationResult.error(
          'HPP murni tidak boleh negatif');
    }

    if (hpp > AppConstants.maxPrice) {
      return OperationalCalculationResult.error('HPP murni terlalu besar');
    }

    // Validasi estimasi porsi
    final porsiValidation = InputValidator.validateQuantity(porsi.toString());
    if (porsiValidation != null) {
      return OperationalCalculationResult.error(
          'Estimasi Porsi: $porsiValidation');
    }

    // Validasi estimasi produksi
    final produksiValidation =
        InputValidator.validateQuantity(produksi.toString());
    if (produksiValidation != null) {
      return OperationalCalculationResult.error(
          'Estimasi Produksi: $produksiValidation');
    }

    // Check against constants
    if (porsi > AppConstants.maxQuantity) {
      return OperationalCalculationResult.error(
          'Estimasi porsi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    if (produksi > AppConstants.maxQuantity) {
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

  /// FIXED: Menghitung proyeksi operational bulanan dengan explicit double conversion
  static Map<String, dynamic> calculateOperationalProjection({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // FIXED: Explicit double conversion
    double porsi = estimasiPorsiPerProduksi.toDouble();
    double produksi = estimasiProduksiBulanan.toDouble();

    double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
    double totalPorsiBulanan = porsi * produksi;
    double operationalPerPorsi =
        totalPorsiBulanan > 0 ? totalGajiBulanan / totalPorsiBulanan : 0.0;
    double operationalPerHari =
        totalGajiBulanan / 30; // Asumsi 30 hari per bulan
    double averageGajiPerKaryawan =
        karyawan.isNotEmpty ? totalGajiBulanan / karyawan.length : 0.0;

    return {
      'isAvailable': true,
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

  /// FIXED: Analisis efisiensi karyawan dengan detailed metrics dan type conversion
  static Map<String, dynamic> analyzeKaryawanEfficiency({
    required List<KaryawanData> karyawan,
    required double totalPorsiBulanan,
  }) {
    // FIXED: Explicit double conversion
    double totalPorsi = totalPorsiBulanan.toDouble();

    if (karyawan.isEmpty || totalPorsi <= 0) {
      return {
        'isAvailable': false,
        'averageGajiPerKaryawan': 0.0,
        'costPerKaryawanPerPorsi': 0.0,
        'porsiPerKaryawan': 0.0,
        'efficiency': 'N/A',
        'recommendation': 'Tidak ada data karyawan untuk analisis',
        'message': 'Tambahkan data karyawan terlebih dahulu',
      };
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);
    double averageGajiPerKaryawan = totalGaji / karyawan.length;
    double costPerKaryawanPerPorsi = totalGaji / (karyawan.length * totalPorsi);
    double porsiPerKaryawan = totalPorsi / karyawan.length;

    String efficiency = _getEfficiencyLevel(porsiPerKaryawan);
    String recommendation =
        _getEfficiencyRecommendation(porsiPerKaryawan, karyawan.length);

    return {
      'isAvailable': true,
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

      // FIXED: Explicit double conversion for validation
      double gaji = k.gajiBulanan.toDouble();
      final gajiValid = InputValidator.validateSalary(gaji.toString()) == null;

      return namaValid && jabatanValid && gajiValid;
    });
  }

  /// Estimate required staff berdasarkan target produksi dengan type conversion
  static Map<String, dynamic> estimateRequiredStaff({
    required double targetPorsiBulanan,
    required double averageProductivityPerStaff,
  }) {
    // FIXED: Explicit double conversion
    double target = targetPorsiBulanan.toDouble();
    double productivity = averageProductivityPerStaff.toDouble();

    if (productivity <= 0) {
      return {
        'requiredStaff': 0,
        'recommendation': 'Tidak dapat menghitung tanpa data produktivitas',
        'isRealistic': false,
      };
    }

    int requiredStaff = (target / productivity).ceil();
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
      'targetPorsiBulanan': target,
      'productivityPerStaff': productivity,
    };
  }
}
