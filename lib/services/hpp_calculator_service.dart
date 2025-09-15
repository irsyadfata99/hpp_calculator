// lib/services/hpp_calculator_service.dart - FIXED: Safe Calculations with Division by Zero Protection
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

/// Result class untuk menyimpan hasil perhitungan HPP
class HPPCalculationResult {
  final double biayaVariablePerPorsi;
  final double biayaFixedPerPorsi;
  final double hppMurniPerPorsi;
  final double totalBiayaBahanBaku;
  final double totalBiayaFixedBulanan;
  final double totalPorsiBulanan;
  final bool isValid;
  final String? errorMessage;

  HPPCalculationResult({
    required this.biayaVariablePerPorsi,
    required this.biayaFixedPerPorsi,
    required this.hppMurniPerPorsi,
    required this.totalBiayaBahanBaku,
    required this.totalBiayaFixedBulanan,
    required this.totalPorsiBulanan,
    required this.isValid,
    this.errorMessage,
  });

  factory HPPCalculationResult.error(String message) {
    return HPPCalculationResult(
      biayaVariablePerPorsi: 0.0,
      biayaFixedPerPorsi: 0.0,
      hppMurniPerPorsi: 0.0,
      totalBiayaBahanBaku: 0.0,
      totalBiayaFixedBulanan: 0.0,
      totalPorsiBulanan: 0.0,
      isValid: false,
      errorMessage: message,
    );
  }

  factory HPPCalculationResult.success({
    required double biayaVariablePerPorsi,
    required double biayaFixedPerPorsi,
    required double hppMurniPerPorsi,
    required double totalBiayaBahanBaku,
    required double totalBiayaFixedBulanan,
    required double totalPorsiBulanan,
  }) {
    return HPPCalculationResult(
      biayaVariablePerPorsi: biayaVariablePerPorsi,
      biayaFixedPerPorsi: biayaFixedPerPorsi,
      hppMurniPerPorsi: hppMurniPerPorsi,
      totalBiayaBahanBaku: totalBiayaBahanBaku,
      totalBiayaFixedBulanan: totalBiayaFixedBulanan,
      totalPorsiBulanan: totalPorsiBulanan,
      isValid: true,
    );
  }

  @override
  String toString() {
    return 'HPPCalculationResult(isValid: $isValid, hppMurni: ${AppFormatters.formatRupiah(hppMurniPerPorsi)}, error: $errorMessage)';
  }
}

class HPPCalculatorService {
  /// FIXED: Safe HPP calculation with comprehensive division by zero protection
  static HPPCalculationResult calculateHPP({
    required List<Map<String, dynamic>> variableCosts,
    required List<Map<String, dynamic>> fixedCosts,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // FIXED: Comprehensive input validation with division by zero protection
      final validationResult = _validateCalculationInputs(
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      if (!validationResult.isValid) {
        return validationResult;
      }

      // Validate data lists
      final dataValidation = _validateDataLists(variableCosts, fixedCosts);
      if (!dataValidation.isValid) {
        return dataValidation;
      }

      // Calculate totals safely
      double totalBiayaBahanBaku = _calculateTotalVariableCosts(variableCosts);
      double totalBiayaFixedBulanan = _calculateTotalFixedCosts(fixedCosts);

      // FIXED: Division by zero protection for estimasiPorsiPerProduksi
      if (estimasiPorsiPerProduksi <= 0) {
        return HPPCalculationResult.error(
            'Estimasi porsi per produksi harus lebih dari 0');
      }

      // Calculate variable cost per portion safely
      double biayaVariablePerPorsi =
          totalBiayaBahanBaku / estimasiPorsiPerProduksi;

      // Calculate total portions per month safely
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // FIXED: Division by zero protection for totalPorsiBulanan
      if (totalPorsiBulanan <= 0) {
        return HPPCalculationResult.error(
            'Total porsi bulanan harus lebih dari 0');
      }

      // Calculate fixed cost per portion safely
      double biayaFixedPerPorsi = totalBiayaFixedBulanan / totalPorsiBulanan;

      // Calculate final HPP
      double hppMurniPerPorsi = biayaVariablePerPorsi + biayaFixedPerPorsi;

      // FIXED: Validate final result for safety
      if (!_isValidResult(hppMurniPerPorsi)) {
        return HPPCalculationResult.error('Hasil perhitungan tidak valid');
      }

      return HPPCalculationResult.success(
        biayaVariablePerPorsi: biayaVariablePerPorsi,
        biayaFixedPerPorsi: biayaFixedPerPorsi,
        hppMurniPerPorsi: hppMurniPerPorsi,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        totalBiayaFixedBulanan: totalBiayaFixedBulanan,
        totalPorsiBulanan: totalPorsiBulanan,
      );
    } catch (e) {
      return HPPCalculationResult.error(
          'Error dalam perhitungan: ${e.toString()}');
    }
  }

  /// FIXED: Enhanced input validation with division by zero protection
  static HPPCalculationResult _validateCalculationInputs({
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // FIXED: Division by zero protection
    if (estimasiPorsiPerProduksi <= 0) {
      return HPPCalculationResult.error(
          'Estimasi Porsi per Produksi harus lebih dari 0');
    }

    if (estimasiProduksiBulanan <= 0) {
      return HPPCalculationResult.error(
          'Estimasi Produksi Bulanan harus lebih dari 0');
    }

    // Check maximum limits
    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity) {
      return HPPCalculationResult.error(
          'Estimasi porsi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    if (estimasiProduksiBulanan > AppConstants.maxQuantity) {
      return HPPCalculationResult.error(
          'Estimasi produksi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    // FIXED: Check for reasonable total portions to prevent overflow
    double totalPorsi = estimasiPorsiPerProduksi * estimasiProduksiBulanan;
    if (totalPorsi > 1000000) {
      // Reasonable limit
      return HPPCalculationResult.error(
          'Total porsi bulanan terlalu besar (${totalPorsi.toStringAsFixed(0)}). Periksa kembali estimasi Anda.');
    }

    return HPPCalculationResult.success(
      biayaVariablePerPorsi: 0.0,
      biayaFixedPerPorsi: 0.0,
      hppMurniPerPorsi: 0.0,
      totalBiayaBahanBaku: 0.0,
      totalBiayaFixedBulanan: 0.0,
      totalPorsiBulanan: totalPorsi,
    );
  }

  /// FIXED: Enhanced data validation
  static HPPCalculationResult _validateDataLists(
    List<Map<String, dynamic>> variableCosts,
    List<Map<String, dynamic>> fixedCosts,
  ) {
    // Variable costs validation
    if (variableCosts.isEmpty) {
      return HPPCalculationResult.error(
          'Data belanja bahan tidak boleh kosong');
    }

    for (int i = 0; i < variableCosts.length; i++) {
      final item = variableCosts[i];

      // Validate name
      final namaValidation =
          InputValidator.validateName(item['nama']?.toString());
      if (namaValidation != null) {
        return HPPCalculationResult.error('Bahan ke-${i + 1}: $namaValidation');
      }

      // Validate total price
      final hargaValidation =
          InputValidator.validatePrice(item['totalHarga']?.toString());
      if (hargaValidation != null) {
        return HPPCalculationResult.error(
            'Bahan "${item['nama']}" ke-${i + 1}: $hargaValidation');
      }

      // Validate quantity - FIXED: Division by zero protection
      final jumlahValidation =
          InputValidator.validateQuantity(item['jumlah']?.toString());
      if (jumlahValidation != null) {
        return HPPCalculationResult.error(
            'Bahan "${item['nama']}" ke-${i + 1}: $jumlahValidation');
      }

      // FIXED: Additional safety check for zero quantity
      double? jumlah = _parseDouble(item['jumlah']);
      if (jumlah == null || jumlah <= 0) {
        return HPPCalculationResult.error(
            'Jumlah bahan "${item['nama']}" harus lebih dari 0');
      }
    }

    // Fixed costs validation (optional)
    for (int i = 0; i < fixedCosts.length; i++) {
      final item = fixedCosts[i];

      final jenisValidation =
          InputValidator.validateName(item['jenis']?.toString());
      if (jenisValidation != null) {
        return HPPCalculationResult.error(
            'Biaya tetap ke-${i + 1}: $jenisValidation');
      }

      final nominalValidation =
          InputValidator.validatePrice(item['nominal']?.toString());
      if (nominalValidation != null) {
        return HPPCalculationResult.error(
            'Biaya tetap "${item['jenis']}" ke-${i + 1}: $nominalValidation');
      }
    }

    return HPPCalculationResult.success(
      biayaVariablePerPorsi: 0.0,
      biayaFixedPerPorsi: 0.0,
      hppMurniPerPorsi: 0.0,
      totalBiayaBahanBaku: 0.0,
      totalBiayaFixedBulanan: 0.0,
      totalPorsiBulanan: 0.0,
    );
  }

  /// FIXED: Safe calculation of total variable costs
  static double _calculateTotalVariableCosts(
      List<Map<String, dynamic>> variableCosts) {
    if (variableCosts.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in variableCosts) {
      try {
        double totalHarga = _parseDouble(item['totalHarga']) ?? 0.0;
        if (totalHarga < 0) continue;
        if (totalHarga > AppConstants.maxPrice) continue;
        total += totalHarga;
      } catch (e) {
        continue; // Skip problematic items
      }
    }
    return total;
  }

  /// FIXED: Safe calculation of total fixed costs
  static double _calculateTotalFixedCosts(
      List<Map<String, dynamic>> fixedCosts) {
    if (fixedCosts.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in fixedCosts) {
      try {
        double nominal = _parseDouble(item['nominal']) ?? 0.0;
        if (nominal < 0) continue;
        if (nominal > AppConstants.maxPrice) continue;
        total += nominal;
      } catch (e) {
        continue; // Skip problematic items
      }
    }
    return total;
  }

  /// FIXED: Safe double parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) return value.isFinite ? value : null;
      if (value is int) return value.toDouble();
      if (value is String) {
        String cleaned = InputValidator.cleanNumericInput(value);
        if (cleaned.isEmpty) return null;
        double? parsed = double.tryParse(cleaned);
        return (parsed?.isFinite == true) ? parsed : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// FIXED: Enhanced result validation
  static bool _isValidResult(double hppMurniPerPorsi) {
    if (!hppMurniPerPorsi.isFinite || hppMurniPerPorsi.isNaN) {
      return false;
    }
    if (hppMurniPerPorsi < 0) {
      return false;
    }
    if (hppMurniPerPorsi > AppConstants.maxPrice) {
      return false;
    }
    return true;
  }

  /// FIXED: Safe calculation of unit price with division by zero protection
  static double calculateHargaPerSatuan({
    required double totalHarga,
    required double jumlah,
  }) {
    if (jumlah <= 0 || totalHarga < 0) return 0.0;

    try {
      double result = totalHarga / jumlah;
      return result.isFinite ? result : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// Format percentage untuk display
  static String formatPercentage(double percentage) {
    return AppFormatters.formatPercentage(percentage);
  }

  /// FIXED: Safe break-even calculation with division by zero protection
  static Map<String, double> calculateBreakEven({
    required double totalBiayaFixedBulanan,
    required double hargaJualPerPorsi,
    required double biayaVariablePerPorsi,
  }) {
    // FIXED: Division by zero protection
    if (hargaJualPerPorsi <= biayaVariablePerPorsi || hargaJualPerPorsi <= 0) {
      return {
        'breakEvenPorsi': double.infinity,
        'breakEvenHari': double.infinity,
        'contributionMargin': 0.0,
      };
    }

    try {
      double contributionMargin = hargaJualPerPorsi - biayaVariablePerPorsi;

      // FIXED: Additional safety check
      if (contributionMargin <= 0) {
        return {
          'breakEvenPorsi': double.infinity,
          'breakEvenHari': double.infinity,
          'contributionMargin': 0.0,
        };
      }

      double breakEvenPorsi = totalBiayaFixedBulanan / contributionMargin;
      double breakEvenHari = breakEvenPorsi / 30; // Per hari

      return {
        'breakEvenPorsi':
            breakEvenPorsi.isFinite ? breakEvenPorsi : double.infinity,
        'breakEvenHari':
            breakEvenHari.isFinite ? breakEvenHari : double.infinity,
        'contributionMargin': contributionMargin,
      };
    } catch (e) {
      return {
        'breakEvenPorsi': double.infinity,
        'breakEvenHari': double.infinity,
        'contributionMargin': 0.0,
      };
    }
  }
}
