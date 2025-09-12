// File: lib/services/hpp_calculator_service.dart

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
}

class HPPCalculatorService {
  /// Menghitung HPP berdasarkan rumus yang benar sesuai gambar:
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
      // Validasi input
      final validationResult = _validateInputs(
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      if (!validationResult.isValid) {
        return HPPCalculationResult.error(validationResult.errorMessage!);
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

      return HPPCalculationResult(
        biayaVariablePerPorsi: biayaVariablePerPorsi,
        biayaFixedPerPorsi: biayaFixedPerPorsi,
        hppMurniPerPorsi: hppMurniPerPorsi,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        totalBiayaFixedBulanan: totalBiayaFixedBulanan,
        totalPorsiBulanan: totalPorsiBulanan,
        isValid: true,
      );
    } catch (e) {
      return HPPCalculationResult.error(
          'Error dalam perhitungan: ${e.toString()}');
    }
  }

  /// Validasi input parameters
  static HPPCalculationResult _validateInputs({
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    if (estimasiPorsiPerProduksi <= 0) {
      return HPPCalculationResult.error(
          'Estimasi Porsi per Produksi harus lebih besar dari 0');
    }

    if (estimasiProduksiBulanan <= 0) {
      return HPPCalculationResult.error(
          'Estimasi Produksi Bulanan harus lebih besar dari 0');
    }

    return HPPCalculationResult(
      biayaVariablePerPorsi: 0.0,
      biayaFixedPerPorsi: 0.0,
      hppMurniPerPorsi: 0.0,
      totalBiayaBahanBaku: 0.0,
      totalBiayaFixedBulanan: 0.0,
      totalPorsiBulanan: 0.0,
      isValid: true,
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
          throw ArgumentError('Total harga tidak boleh negatif');
        }
        total += totalHarga;
      } catch (e) {
        // Log error atau skip item yang bermasalah
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
          throw ArgumentError('Nominal tidak boleh negatif');
        }
        total += nominal;
      } catch (e) {
        // Log error atau skip item yang bermasalah
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
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Menghitung harga per satuan untuk variable cost item
  static double calculateHargaPerSatuan({
    required double totalHarga,
    required double jumlah,
  }) {
    if (jumlah <= 0) return 0.0;
    return totalHarga / jumlah;
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

  /// Menghitung proyeksi bulanan
  static Map<String, double> calculateMonthlyProjection({
    required double hppMurniPerPorsi,
    required double estimasiPorsiPerProduksi,
    required double estimasiProduksiBulanan,
  }) {
    double totalPorsiBulanan =
        estimasiPorsiPerProduksi * estimasiProduksiBulanan;
    double totalHPPBulanan = hppMurniPerPorsi * totalPorsiBulanan;

    return {
      'totalPorsiBulanan': totalPorsiBulanan,
      'totalHPPBulanan': totalHPPBulanan,
      'hppPerHari': totalHPPBulanan / 30, // Asumsi 30 hari per bulan
    };
  }
}
