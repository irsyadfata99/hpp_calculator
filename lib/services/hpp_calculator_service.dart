// File: lib/services/hpp_calculator_service.dart

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

  /// Factory constructor untuk membuat result dengan error
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

  /// Factory constructor untuk result yang valid
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

  /// Convert ke Map untuk serialization
  Map<String, dynamic> toMap() {
    return {
      'biayaVariablePerPorsi': biayaVariablePerPorsi,
      'biayaFixedPerPorsi': biayaFixedPerPorsi,
      'hppMurniPerPorsi': hppMurniPerPorsi,
      'totalBiayaBahanBaku': totalBiayaBahanBaku,
      'totalBiayaFixedBulanan': totalBiayaFixedBulanan,
      'totalPorsiBulanan': totalPorsiBulanan,
      'isValid': isValid,
      'errorMessage': errorMessage,
    };
  }

  /// Create from Map untuk deserialization
  factory HPPCalculationResult.fromMap(Map<String, dynamic> map) {
    return HPPCalculationResult(
      biayaVariablePerPorsi: map['biayaVariablePerPorsi']?.toDouble() ?? 0.0,
      biayaFixedPerPorsi: map['biayaFixedPerPorsi']?.toDouble() ?? 0.0,
      hppMurniPerPorsi: map['hppMurniPerPorsi']?.toDouble() ?? 0.0,
      totalBiayaBahanBaku: map['totalBiayaBahanBaku']?.toDouble() ?? 0.0,
      totalBiayaFixedBulanan: map['totalBiayaFixedBulanan']?.toDouble() ?? 0.0,
      totalPorsiBulanan: map['totalPorsiBulanan']?.toDouble() ?? 0.0,
      isValid: map['isValid'] ?? false,
      errorMessage: map['errorMessage'],
    );
  }

  @override
  String toString() {
    return 'HPPCalculationResult(isValid: $isValid, hppMurni: ${AppFormatters.formatRupiah(hppMurniPerPorsi)}, error: $errorMessage)';
  }
}

/// Service class untuk menghitung HPP (Harga Pokok Penjualan)
class HPPCalculatorService {
  /// Menghitung HPP berdasarkan rumus yang benar sesuai standar akuntansi:
  ///
  /// Rumus 1: Biaya Variabel per Porsi = Total Biaya Bahan Baku ÷ Estimasi Porsi per Produksi
  /// Rumus 2: Biaya Fixed per Porsi = Total Biaya Fixed Bulanan ÷ Total Porsi Bulanan
  /// Rumus 3: HPP Murni = Biaya Variabel per Porsi + Biaya Fixed per Porsi
  ///
  /// Di mana: Total Porsi Bulanan = Estimasi Porsi per Produksi × Estimasi Produksi per Bulan
  static HPPCalculationResult calculateHPP({
    required List<Map<String, dynamic>> variableCosts,
    required List<Map<String, dynamic>> fixedCosts,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    try {
      // Validasi input menggunakan integrated validators
      final validationResult = _validateCalculationInputs(
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      if (!validationResult.isValid) {
        return validationResult;
      }

      // Validasi data lists
      final dataValidation = _validateDataLists(variableCosts, fixedCosts);
      if (!dataValidation.isValid) {
        return dataValidation;
      }

      // Hitung Total Biaya Bahan Baku (semua variable costs)
      double totalBiayaBahanBaku = _calculateTotalVariableCosts(variableCosts);

      // Hitung Total Biaya Fixed Bulanan
      double totalBiayaFixedBulanan = _calculateTotalFixedCosts(fixedCosts);

      // Rumus 1: Biaya Variabel per Porsi = Total Biaya Bahan Baku ÷ Estimasi Porsi per Produksi
      double biayaVariablePerPorsi =
          totalBiayaBahanBaku / estimasiPorsiPerProduksi;

      // Hitung Total Porsi Bulanan = Estimasi Porsi per Produksi × Estimasi Produksi per Bulan
      double totalPorsiBulanan =
          estimasiPorsiPerProduksi * estimasiProduksiBulanan;

      // Rumus 2: Biaya Fixed per Porsi = Total Biaya Fixed Bulanan ÷ Total Porsi Bulanan
      double biayaFixedPerPorsi = totalBiayaFixedBulanan / totalPorsiBulanan;

      // Rumus 3: HPP Murni = Biaya Variabel per Porsi + Biaya Fixed per Porsi
      double hppMurniPerPorsi = biayaVariablePerPorsi + biayaFixedPerPorsi;

      // Validasi hasil akhir
      if (!_isValidResult(hppMurniPerPorsi)) {
        return HPPCalculationResult.error(
            'Hasil perhitungan tidak valid: ${AppFormatters.formatRupiah(hppMurniPerPorsi)}');
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

  /// Validasi input parameters menggunakan integrated validators
  static HPPCalculationResult _validateCalculationInputs({
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // Validasi estimasi porsi per produksi
    if (estimasiPorsiPerProduksi <= AppConstants.minQuantity) {
      return HPPCalculationResult.error(AppConstants.errorZeroQuantity
          .replaceAll('Jumlah', 'Estimasi Porsi per Produksi'));
    }

    if (estimasiPorsiPerProduksi > AppConstants.maxQuantity) {
      return HPPCalculationResult.error(
          'Estimasi Porsi per Produksi terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    // Validasi estimasi produksi bulanan
    if (estimasiProduksiBulanan <= AppConstants.minQuantity) {
      return HPPCalculationResult.error(AppConstants.errorZeroQuantity
          .replaceAll('Jumlah', 'Estimasi Produksi Bulanan'));
    }

    if (estimasiProduksiBulanan > AppConstants.maxQuantity) {
      return HPPCalculationResult.error(
          'Estimasi Produksi Bulanan terlalu besar (maksimal ${AppConstants.maxQuantity})');
    }

    // Validasi kombinasi yang masuk akal
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

  /// Validasi data lists menggunakan integrated validators
  static HPPCalculationResult _validateDataLists(
    List<Map<String, dynamic>> variableCosts,
    List<Map<String, dynamic>> fixedCosts,
  ) {
    // Validasi variable costs
    if (variableCosts.isEmpty) {
      return HPPCalculationResult.error(
          'Data belanja bahan tidak boleh kosong');
    }

    for (int i = 0; i < variableCosts.length; i++) {
      final item = variableCosts[i];

      // Validasi nama
      final namaValidation =
          InputValidator.validateName(item['nama']?.toString());
      if (namaValidation != null) {
        return HPPCalculationResult.error('Bahan ke-${i + 1}: $namaValidation');
      }

      // Validasi total harga
      final hargaValidation =
          InputValidator.validatePrice(item['totalHarga']?.toString());
      if (hargaValidation != null) {
        return HPPCalculationResult.error(
            'Bahan "${item['nama']}" ke-${i + 1}: $hargaValidation');
      }

      // Validasi jumlah
      final jumlahValidation =
          InputValidator.validateQuantity(item['jumlah']?.toString());
      if (jumlahValidation != null) {
        return HPPCalculationResult.error(
            'Bahan "${item['nama']}" ke-${i + 1}: $jumlahValidation');
      }
    }

    // Validasi fixed costs (opsional, boleh kosong)
    for (int i = 0; i < fixedCosts.length; i++) {
      final item = fixedCosts[i];

      // Validasi jenis
      final jenisValidation =
          InputValidator.validateName(item['jenis']?.toString());
      if (jenisValidation != null) {
        return HPPCalculationResult.error(
            'Biaya tetap ke-${i + 1}: $jenisValidation');
      }

      // Validasi nominal
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

  /// Menghitung total biaya variable costs dengan error handling
  static double _calculateTotalVariableCosts(
      List<Map<String, dynamic>> variableCosts) {
    if (variableCosts.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in variableCosts) {
      try {
        double totalHarga = _parseDouble(item['totalHarga']);
        if (totalHarga < 0) {
          print(
              'Warning: Total harga negatif untuk item ${item['nama']}: $totalHarga');
          continue;
        }
        if (totalHarga > AppConstants.maxPrice) {
          print(
              'Warning: Total harga terlalu besar untuk item ${item['nama']}: $totalHarga');
          continue;
        }
        total += totalHarga;
      } catch (e) {
        print('Warning: Item variable cost bermasalah: $e');
        continue;
      }
    }
    return total;
  }

  /// Menghitung total fixed costs dengan error handling
  static double _calculateTotalFixedCosts(
      List<Map<String, dynamic>> fixedCosts) {
    if (fixedCosts.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in fixedCosts) {
      try {
        double nominal = _parseDouble(item['nominal']);
        if (nominal < 0) {
          print(
              'Warning: Nominal negatif untuk item ${item['jenis']}: $nominal');
          continue;
        }
        if (nominal > AppConstants.maxPrice) {
          print(
              'Warning: Nominal terlalu besar untuk item ${item['jenis']}: $nominal');
          continue;
        }
        total += nominal;
      } catch (e) {
        print('Warning: Item fixed cost bermasalah: $e');
        continue;
      }
    }
    return total;
  }

  /// Helper untuk parsing double dengan error handling
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Clean string dari formatting
      String cleaned = InputValidator.cleanNumericInput(value);
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  /// Validasi hasil perhitungan akhir
  static bool _isValidResult(double hppMurniPerPorsi) {
    if (hppMurniPerPorsi.isNaN || hppMurniPerPorsi.isInfinite) {
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

  /// Menghitung harga per satuan untuk variable cost item
  static double calculateHargaPerSatuan({
    required double totalHarga,
    required double jumlah,
  }) {
    if (jumlah <= 0) return 0.0;
    return totalHarga / jumlah;
  }

  /// Format rupiah untuk display menggunakan integrated formatter
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// Format percentage untuk display menggunakan integrated formatter
  static String formatPercentage(double percentage) {
    return AppFormatters.formatPercentage(percentage);
  }

  /// Validasi apakah data input lengkap untuk perhitungan
  static bool isDataComplete({
    required List<Map<String, dynamic>> variableCosts,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    return variableCosts.isNotEmpty &&
        estimasiPorsiPerProduksi > 0 &&
        estimasiProduksiBulanan > 0;
  }

  /// Menghitung proyeksi bulanan dengan detail analisis
  static Map<String, double> calculateMonthlyProjection({
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    double totalPorsiBulanan =
        estimasiPorsiPerProduksi * estimasiProduksiBulanan;
    double totalHPPBulanan = hppMurniPerPorsi * totalPorsiBulanan;
    double hppPerHari = totalHPPBulanan / 30; // Asumsi 30 hari per bulan
    double hppPerMinggu = totalHPPBulanan / 4; // Asumsi 4 minggu per bulan

    return {
      'totalPorsiBulanan': totalPorsiBulanan,
      'totalHPPBulanan': totalHPPBulanan,
      'hppPerHari': hppPerHari,
      'hppPerMinggu': hppPerMinggu,
      'averageHPPPerPorsi': hppMurniPerPorsi,
      'produksiPerHari': estimasiProduksiBulanan / 30,
      'porsiPerHari': totalPorsiBulanan / 30,
    };
  }

  /// Analisis profitabilitas berdasarkan HPP
  static Map<String, dynamic> analyzeProfitability({
    required double hppMurniPerPorsi,
    required double targetMarginPercentage,
  }) {
    double suggestedPrice =
        hppMurniPerPorsi * (1 + (targetMarginPercentage / 100));
    double minimumPrice = hppMurniPerPorsi * 1.1; // Minimum 10% margin
    double profitPerPorsi = suggestedPrice - hppMurniPerPorsi;

    String profitabilityLevel;
    if (targetMarginPercentage >= 100) {
      profitabilityLevel = 'Sangat Tinggi';
    } else if (targetMarginPercentage >= 50) {
      profitabilityLevel = 'Tinggi';
    } else if (targetMarginPercentage >= 25) {
      profitabilityLevel = 'Sedang';
    } else if (targetMarginPercentage >= 10) {
      profitabilityLevel = 'Rendah';
    } else {
      profitabilityLevel = 'Sangat Rendah';
    }

    return {
      'suggestedPrice': suggestedPrice,
      'minimumPrice': minimumPrice,
      'profitPerPorsi': profitPerPorsi,
      'targetMargin': targetMarginPercentage,
      'profitabilityLevel': profitabilityLevel,
      'isViable': targetMarginPercentage >= 10,
    };
  }

  /// Calculate break-even point
  static Map<String, double> calculateBreakEven({
    required double totalBiayaFixedBulanan,
    required double hargaJualPerPorsi,
    required double biayaVariablePerPorsi,
  }) {
    if (hargaJualPerPorsi <= biayaVariablePerPorsi) {
      return {
        'breakEvenPorsi': double.infinity,
        'breakEvenHari': double.infinity,
        'contributionMargin': 0.0,
      };
    }

    double contributionMargin = hargaJualPerPorsi - biayaVariablePerPorsi;
    double breakEvenPorsi = totalBiayaFixedBulanan / contributionMargin;
    double breakEvenHari = breakEvenPorsi / 30; // Per hari

    return {
      'breakEvenPorsi': breakEvenPorsi,
      'breakEvenHari': breakEvenHari,
      'contributionMargin': contributionMargin,
    };
  }

  /// Validate complete calculation setup
  static HPPCalculationResult validateCompleteSetup({
    required List<Map<String, dynamic>> variableCosts,
    required List<Map<String, dynamic>> fixedCosts,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    // Run full validation without calculation
    final inputValidation = _validateCalculationInputs(
      estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
      estimasiProduksiBulanan: estimasiProduksiBulanan,
    );

    if (!inputValidation.isValid) {
      return inputValidation;
    }

    final dataValidation = _validateDataLists(variableCosts, fixedCosts);
    if (!dataValidation.isValid) {
      return dataValidation;
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
}
