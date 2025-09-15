// lib/services/operational_calculator_service.dart - FIXED: Safe Operations with Division by Zero Protection
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

  @override
  String toString() {
    return 'OperationalCalculationResult(valid: $isValid, karyawan: $jumlahKaryawan, total: ${AppFormatters.formatRupiah(totalGajiBulanan)})';
  }
}

class OperationalCalculatorService {
  /// FIXED: Safe calculation of total monthly salary
  static double calculateTotalGajiBulanan(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return 0.0;

    double total = 0.0;
    for (var k in karyawan) {
      try {
        double gaji = k.gajiBulanan;

        // Validate salary
        final salaryValidation = InputValidator.validateSalaryDirect(gaji);
        if (salaryValidation != null) {
          debugPrint(
              'Warning: Invalid salary for ${k.namaKaryawan}: $salaryValidation');
          continue;
        }

        // Check against constants
        if (gaji > AppConstants.maxPrice) {
          debugPrint('Warning: Salary too high for ${k.namaKaryawan}: $gaji');
          continue;
        }

        total += gaji;
      } catch (e) {
        debugPrint(
            'Warning: Error processing salary for ${k.namaKaryawan}: $e');
        continue;
      }
    }

    return total;
  }

  /// FIXED: Safe calculation of operational cost per portion with division by zero protection
  static double calculateOperationalCostPerPorsi({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // FIXED: Division by zero protection
    if (estimasiPorsiPerProduksi <= 0 || estimasiProduksiBulanan <= 0) {
      debugPrint(
          'Warning: Invalid estimation values for operational cost calculation');
      return 0.0;
    }

    // Validate inputs
    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity ||
        estimasiProduksiBulanan > AppConstants.maxQuantity) {
      debugPrint('Warning: Estimation values exceed maximum limits');
      return 0.0;
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);

    try {
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // FIXED: Division by zero protection for total portions
      if (totalPorsiBulanan <= 0) {
        debugPrint('Warning: Total monthly portions is zero or negative');
        return 0.0;
      }

      double result = totalGaji / totalPorsiBulanan;

      // Validate result
      if (!result.isFinite || result.isNaN) {
        debugPrint('Warning: Invalid operational cost calculation result');
        return 0.0;
      }

      if (result > AppConstants.maxPrice) {
        debugPrint(
            'Warning: Operational cost per portion exceeds maximum price');
        return 0.0;
      }

      return result;
    } catch (e) {
      debugPrint('Error calculating operational cost per portion: $e');
      return 0.0;
    }
  }

  /// FIXED: Safe calculation of total price after operational costs
  static double calculateTotalHargaSetelahOperational({
    required double hppMurniPerPorsi,
    required double operationalCostPerPorsi,
  }) {
    // Validate inputs
    if (hppMurniPerPorsi < 0 || operationalCostPerPorsi < 0) {
      debugPrint('Warning: Negative values in total price calculation');
      return 0.0;
    }

    try {
      double total = hppMurniPerPorsi + operationalCostPerPorsi;

      // Validate result
      if (!total.isFinite || total.isNaN) {
        debugPrint('Warning: Invalid total price calculation');
        return 0.0;
      }

      if (total > AppConstants.maxPrice) {
        debugPrint('Warning: Total price exceeds maximum limit');
        return AppConstants.maxPrice;
      }

      return total;
    } catch (e) {
      debugPrint('Error calculating total price after operational: $e');
      return 0.0;
    }
  }

  /// FIXED: Comprehensive operational cost calculation with safety checks
  static OperationalCalculationResult calculateOperationalCost({
    required List<KaryawanData> karyawan,
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // FIXED: Input validation with division by zero protection
      if (estimasiPorsiPerProduksi <= 0) {
        return OperationalCalculationResult.error(
            'Estimasi porsi per produksi harus lebih dari 0');
      }

      if (estimasiProduksiBulanan <= 0) {
        return OperationalCalculationResult.error(
            'Estimasi produksi bulanan harus lebih dari 0');
      }

      if (hppMurniPerPorsi < 0) {
        return OperationalCalculationResult.error(
            'HPP murni tidak boleh negatif');
      }

      // Check reasonable limits
      if (estimasiPorsiPerProduksi > AppConstants.maxQuantity) {
        return OperationalCalculationResult.error(
            'Estimasi porsi terlalu besar');
      }

      if (estimasiProduksiBulanan > AppConstants.maxQuantity) {
        return OperationalCalculationResult.error(
            'Estimasi produksi terlalu besar');
      }

      // Validate karyawan data
      final karyawanValidation = _validateKaryawanData(karyawan);
      if (!karyawanValidation.isValid) {
        return karyawanValidation;
      }

      // Calculate values safely
      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // FIXED: Division by zero protection for total portions
      if (totalPorsiBulanan <= 0) {
        return OperationalCalculationResult.error(
            'Total porsi bulanan harus lebih dari 0');
      }

      double operationalCostPerPorsi = calculateOperationalCostPerPorsi(
        karyawan: karyawan,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

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

  /// FIXED: Safe karyawan data validation
  static OperationalCalculationResult _validateKaryawanData(
      List<KaryawanData> karyawan) {
    // Empty karyawan list is allowed
    for (int i = 0; i < karyawan.length; i++) {
      final k = karyawan[i];

      // Validate name
      final namaValidation = InputValidator.validateName(k.namaKaryawan);
      if (namaValidation != null) {
        return OperationalCalculationResult.error(
            'Karyawan ke-${i + 1}: $namaValidation');
      }

      // Validate position
      final jabatanValidation = InputValidator.validateName(k.jabatan);
      if (jabatanValidation != null) {
        return OperationalCalculationResult.error(
            'Jabatan karyawan "${k.namaKaryawan}": $jabatanValidation');
      }

      // FIXED: Direct salary validation
      double gaji = k.gajiBulanan;
      final salaryValidation = InputValidator.validateSalaryDirect(gaji);
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

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// FIXED: Safe monthly projection calculation with division by zero protection
  static Map<String, dynamic> calculateOperationalProjection({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // FIXED: Division by zero protection
      if (estimasiPorsiPerProduksi <= 0 || estimasiProduksiBulanan <= 0) {
        return {
          'isAvailable': false,
          'message': 'Invalid estimation values for projection',
        };
      }

      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // FIXED: Safe division
      double operationalPerPorsi =
          totalPorsiBulanan > 0 ? totalGajiBulanan / totalPorsiBulanan : 0.0;
      double operationalPerHari =
          totalGajiBulanan / 30; // Assume 30 days per month
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
      };
    } catch (e) {
      return {
        'isAvailable': false,
        'message': 'Error calculating projection: ${e.toString()}',
      };
    }
  }

  /// FIXED: Safe efficiency analysis with division by zero protection
  static Map<String, dynamic> analyzeKaryawanEfficiency({
    required List<KaryawanData> karyawan,
    required double totalPorsiBulanan,
  }) {
    try {
      // FIXED: Division by zero protection
      if (karyawan.isEmpty || totalPorsiBulanan <= 0) {
        return {
          'isAvailable': false,
          'message': 'Insufficient data for efficiency analysis',
        };
      }

      double totalGaji = calculateTotalGajiBulanan(karyawan);
      double averageGajiPerKaryawan = totalGaji / karyawan.length;

      // FIXED: Safe division for cost calculation
      double costPerKaryawanPerPorsi =
          totalGaji / (karyawan.length * totalPorsiBulanan);
      double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

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
    } catch (e) {
      return {
        'isAvailable': false,
        'message': 'Error analyzing efficiency: ${e.toString()}',
      };
    }
  }

  /// Helper for efficiency analysis
  static bool _analyzeEfficiency(
      List<KaryawanData> karyawan, double totalPorsiBulanan) {
    if (karyawan.isEmpty || totalPorsiBulanan <= 0) return true;

    try {
      double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;
      return porsiPerKaryawan >=
          200; // Target minimum 200 portions per employee per month
    } catch (e) {
      return false;
    }
  }

  /// Helper for efficiency level
  static String _getEfficiencyLevel(double porsiPerKaryawan) {
    if (porsiPerKaryawan >= 400) return 'Sangat Efisien';
    if (porsiPerKaryawan >= 300) return 'Efisien';
    if (porsiPerKaryawan >= 200) return 'Cukup Efisien';
    if (porsiPerKaryawan >= 100) return 'Kurang Efisien';
    return 'Tidak Efisien';
  }

  /// Helper for efficiency recommendation
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

  /// Validate if karyawan data is complete
  static bool isKaryawanDataComplete(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return false;

    return karyawan.every((k) {
      final namaValid = InputValidator.validateName(k.namaKaryawan) == null;
      final jabatanValid = InputValidator.validateName(k.jabatan) == null;
      final gajiValid =
          InputValidator.validateSalaryDirect(k.gajiBulanan) == null;
      return namaValid && jabatanValid && gajiValid;
    });
  }

  /// FIXED: Safe staff estimation with division by zero protection
  static Map<String, dynamic> estimateRequiredStaff({
    required double targetPorsiBulanan,
    required double averageProductivityPerStaff,
  }) {
    try {
      // FIXED: Division by zero protection
      if (averageProductivityPerStaff <= 0) {
        return {
          'requiredStaff': 0,
          'recommendation': 'Cannot calculate without productivity data',
          'isRealistic': false,
        };
      }

      if (targetPorsiBulanan <= 0) {
        return {
          'requiredStaff': 0,
          'recommendation': 'Target portions must be greater than 0',
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
    } catch (e) {
      return {
        'requiredStaff': 0,
        'recommendation':
            'Error calculating staff requirements: ${e.toString()}',
        'isRealistic': false,
      };
    }
  }
}
