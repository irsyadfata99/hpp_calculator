// lib/services/operational_calculator_service.dart - HIGH PRIORITY FIX: Calculation Accuracy + Division Protection
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
  // HIGH PRIORITY FIX: Enhanced calculation constants for accuracy
  static const double _minReasonableTotalPorsi =
      10.0; // Minimum reasonable total portions per month
  static const double _maxReasonableCostPerPorsi =
      100000.0; // Maximum reasonable operational cost per portion (100k IDR)
  static const double _minReasonableCostPerPorsi =
      100.0; // Minimum reasonable operational cost per portion (100 IDR)

  /// HIGH PRIORITY FIX: Enhanced calculation of total monthly salary with validation
  static double calculateTotalGajiBulanan(List<KaryawanData> karyawan) {
    if (karyawan.isEmpty) return 0.0;

    double total = 0.0;
    for (var k in karyawan) {
      try {
        double gaji = k.gajiBulanan;

        // HIGH PRIORITY FIX: Enhanced salary validation
        final salaryValidation = InputValidator.validateSalaryDirect(gaji);
        if (salaryValidation != null) {
          debugPrint(
              'Warning: Invalid salary for ${k.namaKaryawan}: $salaryValidation');
          continue;
        }

        // HIGH PRIORITY FIX: Additional business logic validation
        if (gaji < AppConstants.minSalary || gaji > AppConstants.maxSalary) {
          debugPrint(
              'Warning: Salary out of range for ${k.namaKaryawan}: $gaji');
          continue;
        }

        // HIGH PRIORITY FIX: Check for reasonable salary ranges
        if (!_isReasonableSalary(gaji)) {
          debugPrint(
              'Warning: Unreasonable salary detected for ${k.namaKaryawan}: $gaji');
          // Still add it but log the warning
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

  /// HIGH PRIORITY FIX: Enhanced calculation with comprehensive division protection + accuracy validation
  static double calculateOperationalCostPerPorsi({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // HIGH PRIORITY FIX: Enhanced input validation with specific error messages
    if (estimasiPorsiPerProduksi <= 0) {
      debugPrint(
          'CRITICAL: estimasiPorsiPerProduksi is zero or negative: $estimasiPorsiPerProduksi');
      return 0.0;
    }

    if (estimasiProduksiBulanan <= 0) {
      debugPrint(
          'CRITICAL: estimasiProduksiBulanan is zero or negative: $estimasiProduksiBulanan');
      return 0.0;
    }

    // HIGH PRIORITY FIX: Validate against reasonable limits
    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity ||
        estimasiProduksiBulanan > AppConstants.maxQuantity) {
      debugPrint('Warning: Estimation values exceed maximum limits');
      return 0.0;
    }

    double totalGaji = calculateTotalGajiBulanan(karyawan);

    // HIGH PRIORITY FIX: Early return if no salary costs
    if (totalGaji <= 0) {
      return 0.0;
    }

    try {
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // HIGH PRIORITY FIX: CRITICAL - Enhanced division by zero protection with reasonable minimums
      if (totalPorsiBulanan <= 0) {
        debugPrint(
            'CRITICAL: totalPorsiBulanan is zero or negative: $totalPorsiBulanan');
        return 0.0;
      }

      // HIGH PRIORITY FIX: Check for unreasonably small total portions that would cause inflated costs
      if (totalPorsiBulanan < _minReasonableTotalPorsi) {
        debugPrint(
            'WARNING: Very small total portions detected ($totalPorsiBulanan). This may result in unrealistic operational costs.');

        // HIGH PRIORITY FIX: Apply minimum reasonable total portions to prevent unrealistic calculations
        double adjustedTotalPorsi = _minReasonableTotalPorsi;
        double result = totalGaji / adjustedTotalPorsi;

        debugPrint(
            'INFO: Using adjusted total portions: $adjustedTotalPorsi instead of $totalPorsiBulanan');
        debugPrint(
            'INFO: Original cost would be: ${totalGaji / totalPorsiBulanan}, Adjusted cost: $result');

        return _validateOperationalCostResult(result);
      }

      double result = totalGaji / totalPorsiBulanan;

      // HIGH PRIORITY FIX: Validate result for business logic reasonableness
      return _validateOperationalCostResult(result);
    } catch (e) {
      debugPrint('CRITICAL ERROR in operational cost calculation: $e');
      return 0.0;
    }
  }

  /// HIGH PRIORITY FIX: Enhanced validation of operational cost results
  static double _validateOperationalCostResult(double result) {
    // Check for mathematical validity
    if (!result.isFinite || result.isNaN) {
      debugPrint(
          'CRITICAL: Invalid operational cost result (NaN/Infinity): $result');
      return 0.0;
    }

    if (result < 0) {
      debugPrint('CRITICAL: Negative operational cost result: $result');
      return 0.0;
    }

    // HIGH PRIORITY FIX: Check for business logic reasonableness
    if (result > _maxReasonableCostPerPorsi) {
      debugPrint(
          'WARNING: Operational cost per portion is very high: ${AppFormatters.formatRupiah(result)}');
      debugPrint(
          'This suggests either very high salaries or very low production volume.');

      // HIGH PRIORITY FIX: Cap at reasonable maximum to prevent unrealistic results
      double cappedResult = _maxReasonableCostPerPorsi;
      debugPrint(
          'INFO: Capping operational cost at: ${AppFormatters.formatRupiah(cappedResult)}');
      return cappedResult;
    }

    if (result < _minReasonableCostPerPorsi) {
      debugPrint(
          'INFO: Very low operational cost per portion: ${AppFormatters.formatRupiah(result)}');
      // This might be valid for very high volume operations, so we allow it
    }

    return result;
  }

  /// HIGH PRIORITY FIX: Enhanced salary reasonableness check
  static bool _isReasonableSalary(double salary) {
    // Indonesian context - reasonable salary ranges
    const double minReasonableSalary = 1000000.0; // 1 million IDR (basic UMR)
    const double maxReasonableSalary =
        50000000.0; // 50 million IDR (executive level)

    return salary >= minReasonableSalary && salary <= maxReasonableSalary;
  }

  /// HIGH PRIORITY FIX: Enhanced calculation of total price after operational costs with validation
  static double calculateTotalHargaSetelahOperational({
    required double hppMurniPerPorsi,
    required double operationalCostPerPorsi,
  }) {
    // HIGH PRIORITY FIX: Enhanced input validation
    if (hppMurniPerPorsi < 0) {
      debugPrint('WARNING: Negative HPP value: $hppMurniPerPorsi');
      hppMurniPerPorsi = 0.0;
    }

    if (operationalCostPerPorsi < 0) {
      debugPrint(
          'WARNING: Negative operational cost: $operationalCostPerPorsi');
      operationalCostPerPorsi = 0.0;
    }

    try {
      double total = hppMurniPerPorsi + operationalCostPerPorsi;

      // HIGH PRIORITY FIX: Validate result
      if (!total.isFinite || total.isNaN) {
        debugPrint('CRITICAL: Invalid total price calculation');
        return 0.0;
      }

      // HIGH PRIORITY FIX: Business logic validation
      if (total > AppConstants.maxPrice) {
        debugPrint(
            'WARNING: Total price exceeds maximum limit: ${AppFormatters.formatRupiah(total)}');
        return AppConstants.maxPrice;
      }

      // HIGH PRIORITY FIX: Check for reasonable price proportions
      if (operationalCostPerPorsi > 0 && hppMurniPerPorsi > 0) {
        double operationalRatio = (operationalCostPerPorsi / total) * 100;

        if (operationalRatio > 80) {
          debugPrint(
              'WARNING: Operational cost is ${operationalRatio.toStringAsFixed(1)}% of total price. This is unusually high.');
        } else if (operationalRatio > 50) {
          debugPrint(
              'INFO: Operational cost is ${operationalRatio.toStringAsFixed(1)}% of total price.');
        }
      }

      return total;
    } catch (e) {
      debugPrint('CRITICAL ERROR in total price calculation: $e');
      return 0.0;
    }
  }

  /// HIGH PRIORITY FIX: Comprehensive operational cost calculation with enhanced validation
  static OperationalCalculationResult calculateOperationalCost({
    required List<KaryawanData> karyawan,
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // HIGH PRIORITY FIX: Enhanced input validation with specific error messages
      if (estimasiPorsiPerProduksi <= 0) {
        return OperationalCalculationResult.error(
            'Estimasi porsi per produksi harus lebih dari 0 (saat ini: $estimasiPorsiPerProduksi)');
      }

      if (estimasiProduksiBulanan <= 0) {
        return OperationalCalculationResult.error(
            'Estimasi produksi bulanan harus lebih dari 0 (saat ini: $estimasiProduksiBulanan)');
      }

      if (hppMurniPerPorsi < 0) {
        return OperationalCalculationResult.error(
            'HPP murni tidak boleh negatif (saat ini: $hppMurniPerPorsi)');
      }

      // HIGH PRIORITY FIX: Enhanced range validation
      if (estimasiPorsiPerProduksi > AppConstants.maxQuantity) {
        return OperationalCalculationResult.error(
            'Estimasi porsi terlalu besar (maksimal ${AppConstants.maxQuantity})');
      }

      if (estimasiProduksiBulanan > AppConstants.maxQuantity) {
        return OperationalCalculationResult.error(
            'Estimasi produksi terlalu besar (maksimal ${AppConstants.maxQuantity})');
      }

      // HIGH PRIORITY FIX: Enhanced karyawan validation
      final karyawanValidation = _validateKaryawanDataEnhanced(karyawan);
      if (!karyawanValidation.isValid) {
        return karyawanValidation;
      }

      // Calculate values safely
      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // HIGH PRIORITY FIX: Enhanced division by zero protection for total portions
      if (totalPorsiBulanan <= 0) {
        return OperationalCalculationResult.error(
            'Total porsi bulanan harus lebih dari 0 (${estimasiPorsiPerProduksi} × ${estimasiProduksiBulanan} = $totalPorsiBulanan)');
      }

      // HIGH PRIORITY FIX: Check for business logic reasonableness
      if (totalPorsiBulanan < _minReasonableTotalPorsi) {
        String warning =
            'Total porsi bulanan sangat kecil (${totalPorsiBulanan.toStringAsFixed(1)}). ';
        warning +=
            'Ini akan menghasilkan biaya operasional per porsi yang sangat tinggi. ';
        warning += 'Pertimbangkan untuk menaikkan estimasi produksi.';

        debugPrint('BUSINESS WARNING: $warning');
        // Continue with calculation but log the warning
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

      // HIGH PRIORITY FIX: Final result validation
      if (!_validateFinalResults(totalGajiBulanan, operationalCostPerPorsi,
          totalHargaSetelahOperational)) {
        return OperationalCalculationResult.error(
            'Hasil perhitungan tidak valid atau tidak masuk akal untuk UMKM');
      }

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

  /// HIGH PRIORITY FIX: Enhanced karyawan data validation
  static OperationalCalculationResult _validateKaryawanDataEnhanced(
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

      // HIGH PRIORITY FIX: Enhanced salary validation
      double gaji = k.gajiBulanan;
      final salaryValidation = InputValidator.validateSalaryDirect(gaji);
      if (salaryValidation != null) {
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}": $salaryValidation');
      }

      // HIGH PRIORITY FIX: Enhanced business logic validation
      if (gaji < AppConstants.minSalary) {
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}" terlalu rendah: ${AppFormatters.formatRupiah(gaji)} (minimal ${AppFormatters.formatRupiah(AppConstants.minSalary)})');
      }

      if (gaji > AppConstants.maxSalary) {
        return OperationalCalculationResult.error(
            'Gaji karyawan "${k.namaKaryawan}" terlalu tinggi: ${AppFormatters.formatRupiah(gaji)} (maksimal ${AppFormatters.formatRupiah(AppConstants.maxSalary)})');
      }

      // HIGH PRIORITY FIX: Check for reasonable salary
      if (!_isReasonableSalary(gaji)) {
        debugPrint(
            'WARNING: Unusual salary for ${k.namaKaryawan}: ${AppFormatters.formatRupiah(gaji)}');
        // Continue but log warning
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

  /// HIGH PRIORITY FIX: Final results validation
  static bool _validateFinalResults(
      double totalGaji, double operationalPerPorsi, double totalHarga) {
    // Check for mathematical validity
    if (!totalGaji.isFinite ||
        !operationalPerPorsi.isFinite ||
        !totalHarga.isFinite) {
      debugPrint('CRITICAL: Invalid mathematical results detected');
      return false;
    }

    if (totalGaji < 0 || operationalPerPorsi < 0 || totalHarga < 0) {
      debugPrint('CRITICAL: Negative values detected in results');
      return false;
    }

    // Business logic validation
    if (operationalPerPorsi > _maxReasonableCostPerPorsi) {
      debugPrint(
          'WARNING: Operational cost per portion exceeds reasonable limit');
      // Still valid, just high
    }

    if (totalHarga > AppConstants.maxPrice) {
      debugPrint('WARNING: Total price exceeds maximum price limit');
      return false;
    }

    return true;
  }

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// HIGH PRIORITY FIX: Enhanced monthly projection calculation with validation
  static Map<String, dynamic> calculateOperationalProjection({
    required List<KaryawanData> karyawan,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // HIGH PRIORITY FIX: Enhanced input validation
      if (estimasiPorsiPerProduksi <= 0 || estimasiProduksiBulanan <= 0) {
        return {
          'isAvailable': false,
          'message': 'Invalid estimation values for projection',
        };
      }

      double totalGajiBulanan = calculateTotalGajiBulanan(karyawan);
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // HIGH PRIORITY FIX: Enhanced division protection
      double operationalPerPorsi =
          totalPorsiBulanan > 0 ? totalGajiBulanan / totalPorsiBulanan : 0.0;
      double operationalPerHari =
          totalGajiBulanan / 30; // Assume 30 days per month
      double averageGajiPerKaryawan =
          karyawan.isNotEmpty ? totalGajiBulanan / karyawan.length : 0.0;

      // HIGH PRIORITY FIX: Business efficiency analysis
      bool isEfficient =
          _analyzeEfficiencyEnhanced(karyawan, totalPorsiBulanan);
      String efficiencyNote = _getEfficiencyNote(karyawan, totalPorsiBulanan);

      return {
        'isAvailable': true,
        'totalGajiBulanan': totalGajiBulanan,
        'operationalPerPorsi': operationalPerPorsi,
        'operationalPerHari': operationalPerHari,
        'jumlahKaryawan': karyawan.length,
        'totalPorsiBulanan': totalPorsiBulanan,
        'averageGajiPerKaryawan': averageGajiPerKaryawan,
        'isEfficient': isEfficient,
        'efficiencyNote': efficiencyNote,
        'porsiPerKaryawan':
            karyawan.isNotEmpty ? totalPorsiBulanan / karyawan.length : 0.0,
      };
    } catch (e) {
      return {
        'isAvailable': false,
        'message': 'Error calculating projection: ${e.toString()}',
      };
    }
  }

  /// HIGH PRIORITY FIX: Enhanced efficiency analysis
  static Map<String, dynamic> analyzeKaryawanEfficiency({
    required List<KaryawanData> karyawan,
    required double totalPorsiBulanan,
  }) {
    try {
      // HIGH PRIORITY FIX: Enhanced input validation
      if (karyawan.isEmpty || totalPorsiBulanan <= 0) {
        return {
          'isAvailable': false,
          'message': 'Insufficient data for efficiency analysis',
        };
      }

      double totalGaji = calculateTotalGajiBulanan(karyawan);
      double averageGajiPerKaryawan = totalGaji / karyawan.length;

      // HIGH PRIORITY FIX: Enhanced division protection
      double costPerKaryawanPerPorsi =
          totalGaji / (karyawan.length * totalPorsiBulanan);
      double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

      String efficiency = _getEfficiencyLevel(porsiPerKaryawan);
      String recommendation =
          _getEfficiencyRecommendation(porsiPerKaryawan, karyawan.length);

      // HIGH PRIORITY FIX: Additional business metrics
      double gajiRatioToProduction =
          (totalGaji / totalPorsiBulanan) * 100; // Cost per 100 portions

      return {
        'isAvailable': true,
        'averageGajiPerKaryawan': averageGajiPerKaryawan,
        'costPerKaryawanPerPorsi': costPerKaryawanPerPorsi,
        'porsiPerKaryawan': porsiPerKaryawan,
        'efficiency': efficiency,
        'recommendation': recommendation,
        'totalCost': totalGaji,
        'karyawanCount': karyawan.length,
        'gajiRatioToProduction': gajiRatioToProduction,
        'isHighVolume': totalPorsiBulanan >= 1000,
        'isLowVolume': totalPorsiBulanan < 100,
      };
    } catch (e) {
      return {
        'isAvailable': false,
        'message': 'Error analyzing efficiency: ${e.toString()}',
      };
    }
  }

  /// Helper for enhanced efficiency analysis
  static bool _analyzeEfficiencyEnhanced(
      List<KaryawanData> karyawan, double totalPorsiBulanan) {
    if (karyawan.isEmpty || totalPorsiBulanan <= 0) return true;

    try {
      double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

      // HIGH PRIORITY FIX: More nuanced efficiency criteria
      if (totalPorsiBulanan >= 1000) {
        return porsiPerKaryawan >= 250; // High volume operations
      } else if (totalPorsiBulanan >= 500) {
        return porsiPerKaryawan >= 200; // Medium volume operations
      } else {
        return porsiPerKaryawan >= 150; // Small operations
      }
    } catch (e) {
      return false;
    }
  }

  /// Helper for efficiency note
  static String _getEfficiencyNote(
      List<KaryawanData> karyawan, double totalPorsiBulanan) {
    if (karyawan.isEmpty) return 'Tidak ada karyawan';
    if (totalPorsiBulanan <= 0) return 'Tidak ada produksi';

    try {
      double porsiPerKaryawan = totalPorsiBulanan / karyawan.length;

      if (porsiPerKaryawan >= 400) {
        return 'Produktivitas sangat tinggi - pertimbangkan ekspansi';
      } else if (porsiPerKaryawan >= 300) {
        return 'Produktivitas baik - operasi efisien';
      } else if (porsiPerKaryawan >= 200) {
        return 'Produktivitas cukup - ada ruang untuk optimasi';
      } else if (porsiPerKaryawan >= 100) {
        return 'Produktivitas rendah - perlu evaluasi proses';
      } else {
        return 'Produktivitas sangat rendah - pertimbangkan restrukturisasi';
      }
    } catch (e) {
      return 'Error dalam analisis';
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
      return 'Produktivitas sangat baik. Pertimbangkan ekspansi produksi atau penambahan produk.';
    } else if (porsiPerKaryawan >= 300) {
      return 'Produktivitas baik. Monitor konsistensi performa dan pertimbangkan optimasi proses.';
    } else if (porsiPerKaryawan >= 200) {
      return 'Produktivitas cukup. Evaluasi workflow dan proses untuk meningkatkan efisiensi.';
    } else if (porsiPerKaryawan >= 100) {
      return 'Produktivitas rendah. Perlu training karyawan atau perbaikan sistem operasional.';
    } else {
      if (jumlahKaryawan > 5) {
        return 'Produktivitas sangat rendah. Pertimbangkan pengurangan karyawan atau peningkatan volume produksi.';
      } else {
        return 'Produktivitas sangat rendah. Evaluasi model bisnis dan target produksi.';
      }
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

  /// HIGH PRIORITY FIX: Enhanced staff estimation with business logic
  static Map<String, dynamic> estimateRequiredStaff({
    required double targetPorsiBulanan,
    required double averageProductivityPerStaff,
  }) {
    try {
      // HIGH PRIORITY FIX: Enhanced input validation
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
      bool isRealistic = requiredStaff <= 50; // Reasonable limit for UMKM

      String recommendation;
      String businessAdvice = '';

      if (requiredStaff <= 2) {
        recommendation = 'Tim sangat kecil - cocok untuk family business';
        businessAdvice =
            'Pertimbangkan automation untuk meningkatkan kapasitas';
      } else if (requiredStaff <= 5) {
        recommendation = 'Tim kecil - ideal untuk UMKM startup';
        businessAdvice = 'Focus pada training dan skill development';
      } else if (requiredStaff <= 15) {
        recommendation = 'Tim sedang - butuh manajemen yang baik';
        businessAdvice = 'Implementasikan system supervision dan SOP';
      } else if (requiredStaff <= 30) {
        recommendation = 'Tim besar - butuh struktur organisasi yang jelas';
        businessAdvice =
            'Pertimbangkan management layer dan departmentalization';
      } else {
        recommendation =
            'Tim sangat besar - pertimbangkan otomasi atau pembagian shift';
        businessAdvice = 'Evaluasi efisiensi operasional dan teknologi';
        isRealistic = false;
      }

      return {
        'requiredStaff': requiredStaff,
        'recommendation': recommendation,
        'businessAdvice': businessAdvice,
        'isRealistic': isRealistic,
        'targetPorsiBulanan': targetPorsiBulanan,
        'productivityPerStaff': averageProductivityPerStaff,
        'costImplication': _calculateStaffCostImplication(requiredStaff),
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

  /// Helper for staff cost implication
  static Map<String, dynamic> _calculateStaffCostImplication(int staffCount) {
    const double averageSalary = 2500000.0; // 2.5 million IDR average

    double monthlyBudget = staffCount * averageSalary;
    double yearlyBudget = monthlyBudget * 12;

    return {
      'monthlyBudget': monthlyBudget,
      'yearlyBudget': yearlyBudget,
      'formattedMonthly': AppFormatters.formatRupiah(monthlyBudget),
      'formattedYearly': AppFormatters.formatRupiah(yearlyBudget),
    };
  }
}
