// File: lib/services/menu_calculator_service.dart

import '../models/menu_model.dart';
import '../models/karyawan_data.dart';
import 'operational_calculator_service.dart';
import 'hpp_calculator_service.dart';

class MenuCalculationResult {
  final double biayaBahanBakuMenu;
  final double biayaFixedPerMenu;
  final double biayaOperationalPerMenu;
  final double hppMurniPerMenu;
  final double hargaSetelahMargin;
  final double marginPercentage;
  final double profitPerMenu;
  final bool isValid;
  final String? errorMessage;

  MenuCalculationResult({
    required this.biayaBahanBakuMenu,
    required this.biayaFixedPerMenu,
    required this.biayaOperationalPerMenu,
    required this.hppMurniPerMenu,
    required this.hargaSetelahMargin,
    required this.marginPercentage,
    required this.profitPerMenu,
    required this.isValid,
    this.errorMessage,
  });

  factory MenuCalculationResult.error(String message) {
    return MenuCalculationResult(
      biayaBahanBakuMenu: 0.0,
      biayaFixedPerMenu: 0.0,
      biayaOperationalPerMenu: 0.0,
      hppMurniPerMenu: 0.0,
      hargaSetelahMargin: 0.0,
      marginPercentage: 0.0,
      profitPerMenu: 0.0,
      isValid: false,
      errorMessage: message,
    );
  }
}

class MenuCalculatorService {
  /// Menghitung biaya bahan baku untuk menu spesifik
  ///
  /// Rumus: Total Biaya Bahan Menu = Σ(Jumlah Dipakai × Harga per Satuan)
  static double calculateMenuBahanBakuCost(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return 0.0;

    return komposisi.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  /// Menghitung proporsi fixed cost untuk menu
  /// Berdasarkan rasio bahan baku menu terhadap total variable cost
  static double calculateFixedCostProportion({
    required double biayaBahanBakuMenu,
    required double totalBiayaBahanBaku,
    required double biayaFixedPerPorsi,
  }) {
    if (totalBiayaBahanBaku <= 0 || biayaBahanBakuMenu <= 0) return 0.0;

    // Proporsi fixed cost berdasarkan kompleksitas menu
    double proportion = biayaBahanBakuMenu / totalBiayaBahanBaku;
    return biayaFixedPerPorsi * proportion;
  }

  /// Menghitung proporsi operational cost untuk menu
  static double calculateOperationalCostProportion({
    required double biayaBahanBakuMenu,
    required double totalBiayaBahanBaku,
    required double operationalCostPerPorsi,
  }) {
    if (totalBiayaBahanBaku <= 0 || biayaBahanBakuMenu <= 0) return 0.0;

    // Proporsi operational cost berdasarkan kompleksitas menu
    double proportion = biayaBahanBakuMenu / totalBiayaBahanBaku;
    return operationalCostPerPorsi * proportion;
  }

  /// Menghitung harga jual dengan margin
  ///
  /// Rumus: Harga Jual = HPP Murni Menu × (1 + Margin%)
  static double calculateSellingPrice({
    required double hppMurniPerMenu,
    required double marginPercentage,
  }) {
    if (marginPercentage < 0) return hppMurniPerMenu;

    return hppMurniPerMenu * (1 + (marginPercentage / 100));
  }

  /// Menghitung profit per menu
  ///
  /// Rumus: Profit = Harga Jual - HPP Murni Menu
  static double calculateProfitPerMenu({
    required double hargaSetelahMargin,
    required double hppMurniPerMenu,
  }) {
    return hargaSetelahMargin - hppMurniPerMenu;
  }

  /// Perhitungan lengkap untuk menu
  static MenuCalculationResult calculateMenuCost({
    required MenuItem menu,
    required SharedCalculationData sharedData,
    required double marginPercentage,
  }) {
    try {
      // Validasi input
      if (menu.komposisi.isEmpty) {
        return MenuCalculationResult.error(
            'Menu harus memiliki minimal 1 komposisi bahan');
      }

      if (sharedData.hppMurniPerPorsi <= 0) {
        return MenuCalculationResult.error(
            'Data HPP belum tersedia. Silakan lengkapi data HPP terlebih dahulu');
      }

      // 1. Hitung biaya bahan baku menu
      double biayaBahanBakuMenu = calculateMenuBahanBakuCost(menu.komposisi);

      // 2. Hitung total biaya bahan baku dari shared data
      double totalBiayaBahanBaku = sharedData.variableCosts
          .fold(0.0, (sum, item) => sum + item['totalHarga']);

      // 3. Hitung proporsi fixed cost untuk menu
      double biayaFixedPerMenu = calculateFixedCostProportion(
        biayaBahanBakuMenu: biayaBahanBakuMenu,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        biayaFixedPerPorsi: sharedData.biayaFixedPerPorsi,
      );

      // 4. Hitung proporsi operational cost untuk menu
      double operationalCostPerPorsi =
          sharedData.calculateOperationalCostPerPorsi();
      double biayaOperationalPerMenu = calculateOperationalCostProportion(
        biayaBahanBakuMenu: biayaBahanBakuMenu,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        operationalCostPerPorsi: operationalCostPerPorsi,
      );

      // 5. Hitung HPP murni per menu
      double hppMurniPerMenu =
          biayaBahanBakuMenu + biayaFixedPerMenu + biayaOperationalPerMenu;

      // 6. Hitung harga jual dengan margin
      double hargaSetelahMargin = calculateSellingPrice(
        hppMurniPerMenu: hppMurniPerMenu,
        marginPercentage: marginPercentage,
      );

      // 7. Hitung profit per menu
      double profitPerMenu = calculateProfitPerMenu(
        hargaSetelahMargin: hargaSetelahMargin,
        hppMurniPerMenu: hppMurniPerMenu,
      );

      return MenuCalculationResult(
        biayaBahanBakuMenu: biayaBahanBakuMenu,
        biayaFixedPerMenu: biayaFixedPerMenu,
        biayaOperationalPerMenu: biayaOperationalPerMenu,
        hppMurniPerMenu: hppMurniPerMenu,
        hargaSetelahMargin: hargaSetelahMargin,
        marginPercentage: marginPercentage,
        profitPerMenu: profitPerMenu,
        isValid: true,
      );
    } catch (e) {
      return MenuCalculationResult.error(
          'Error dalam perhitungan menu: ${e.toString()}');
    }
  }

  /// Format rupiah untuk display
  static String formatRupiah(double amount) {
    return HPPCalculatorService.formatRupiah(amount);
  }

  /// Mendapatkan daftar ingredient yang tersedia dari variable costs
  static List<Map<String, dynamic>> getAvailableIngredients(
      List<Map<String, dynamic>> variableCosts) {
    return variableCosts.map((item) {
      double hargaPerSatuan = item['totalHarga'] / item['jumlah'];
      return {
        'nama': item['nama'],
        'satuan': item['satuan'],
        'hargaPerSatuan': hargaPerSatuan,
        'stok': item['jumlah'],
      };
    }).toList();
  }

  /// Validasi apakah komposisi menu valid
  static bool isMenuCompositionValid(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return false;

    return komposisi.every((item) =>
        item.namaIngredient.isNotEmpty &&
        item.jumlahDipakai > 0 &&
        item.hargaPerSatuan > 0);
  }

  /// Analisis margin menu
  static Map<String, dynamic> analyzeMenuMargin(MenuCalculationResult result) {
    if (!result.isValid) {
      return {
        'kategori': 'Invalid',
        'rekomendasi': 'Data tidak valid',
        'status': 'error',
      };
    }

    String kategori;
    String rekomendasi;
    String status;

    if (result.marginPercentage >= 100) {
      kategori = 'Premium';
      rekomendasi = 'Margin sangat tinggi, cocok untuk menu premium';
      status = 'excellent';
    } else if (result.marginPercentage >= 50) {
      kategori = 'Profit Tinggi';
      rekomendasi = 'Margin baik, menu menguntungkan';
      status = 'good';
    } else if (result.marginPercentage >= 25) {
      kategori = 'Standard';
      rekomendasi = 'Margin cukup, sesuai standar industri';
      status = 'normal';
    } else if (result.marginPercentage >= 10) {
      kategori = 'Rendah';
      rekomendasi = 'Margin rendah, pertimbangkan untuk dinaikkan';
      status = 'warning';
    } else {
      kategori = 'Sangat Rendah';
      rekomendasi = 'Margin terlalu rendah, revisi diperlukan';
      status = 'danger';
    }

    return {
      'kategori': kategori,
      'rekomendasi': rekomendasi,
      'status': status,
      'profitRatio': (result.profitPerMenu / result.hargaSetelahMargin) * 100,
    };
  }
}
