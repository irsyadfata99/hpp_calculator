// lib/services/menu_calculator_service.dart - FIXED VERSION: PROPER UNIT CALCULATIONS

import '../models/menu_model.dart';
import '../models/shared_calculation_data.dart';
import 'hpp_calculator_service.dart';
import '../utils/constants.dart';

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
  static double calculateMenuBahanBakuCost(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return 0.0;

    return komposisi.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  /// Menghitung proporsi fixed cost untuk menu
  static double calculateFixedCostProportion({
    required double biayaBahanBakuMenu,
    required double totalBiayaBahanBaku,
    required double biayaFixedPerPorsi,
  }) {
    if (totalBiayaBahanBaku <= 0 || biayaBahanBakuMenu <= 0) return 0.0;

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

    double proportion = biayaBahanBakuMenu / totalBiayaBahanBaku;
    return operationalCostPerPorsi * proportion;
  }

  /// Menghitung harga jual dengan margin
  static double calculateSellingPrice({
    required double hppMurniPerMenu,
    required double marginPercentage,
  }) {
    if (marginPercentage < 0) return hppMurniPerMenu;

    return hppMurniPerMenu * (1 + (marginPercentage / 100));
  }

  /// Menghitung profit per menu
  static double calculateProfitPerMenu({
    required double hargaSetelahMargin,
    required double hppMurniPerMenu,
  }) {
    return hargaSetelahMargin - hppMurniPerMenu;
  }

  /// Perhitungan lengkap untuk menu spesifik
  static MenuCalculationResult calculateMenuCost({
    required MenuItem menu,
    required SharedCalculationData sharedData,
    required double marginPercentage,
  }) {
    try {
      if (menu.komposisi.isEmpty) {
        return MenuCalculationResult.error(
            'Menu harus memiliki minimal 1 komposisi bahan');
      }

      if (marginPercentage < AppConstants.minPercentage ||
          marginPercentage > AppConstants.maxPercentage) {
        return MenuCalculationResult.error(
            'Margin harus antara ${AppConstants.minPercentage}% - ${AppConstants.maxPercentage}%');
      }

      for (var komposisi in menu.komposisi) {
        if (komposisi.namaIngredient.trim().isEmpty) {
          return MenuCalculationResult.error(AppConstants.errorEmptyName);
        }

        if (komposisi.namaIngredient.length > AppConstants.maxTextLength) {
          return MenuCalculationResult.error(
              'Nama bahan terlalu panjang (maksimal ${AppConstants.maxTextLength} karakter)');
        }

        if (komposisi.jumlahDipakai <= 0 ||
            komposisi.jumlahDipakai > AppConstants.maxQuantity) {
          return MenuCalculationResult.error(AppConstants.errorInvalidQuantity);
        }

        if (komposisi.hargaPerSatuan < AppConstants.minPrice ||
            komposisi.hargaPerSatuan > AppConstants.maxPrice) {
          return MenuCalculationResult.error(AppConstants.errorInvalidPrice);
        }
      }

      // 1. Hitung biaya bahan baku untuk menu ini (resep)
      double biayaBahanBakuMenu = calculateMenuBahanBakuCost(menu.komposisi);

      // 2. Hitung proporsi fixed cost untuk menu ini
      double totalBiayaBahanBaku = 0.0;
      for (var item in sharedData.variableCosts) {
        final totalHarga = item['totalHarga'];
        if (totalHarga is num) {
          totalBiayaBahanBaku += totalHarga.toDouble();
        }
      }

      double biayaFixedPerMenu = 0.0;
      if (totalBiayaBahanBaku > 0) {
        double proporsi = biayaBahanBakuMenu / totalBiayaBahanBaku;
        biayaFixedPerMenu = sharedData.biayaFixedPerPorsi * proporsi * 1.5;
      }

      // 3. Hitung proporsi operational cost untuk menu ini
      double operationalCostPerPorsi =
          sharedData.calculateOperationalCostPerPorsi();
      double biayaOperationalPerMenu = 0.0;
      if (totalBiayaBahanBaku > 0) {
        double proporsi = biayaBahanBakuMenu / totalBiayaBahanBaku;
        biayaOperationalPerMenu = operationalCostPerPorsi * proporsi;
      }

      // 4. Hitung HPP murni untuk menu ini (1 porsi)
      double hppMurniPerMenu =
          biayaBahanBakuMenu + biayaFixedPerMenu + biayaOperationalPerMenu;

      // 5. Hitung harga jual dengan margin
      double hargaSetelahMargin = calculateSellingPrice(
        hppMurniPerMenu: hppMurniPerMenu,
        marginPercentage: marginPercentage,
      );

      // 6. Hitung profit per menu
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

  /// FIXED: Enhanced getAvailableIngredients with PROPER UNIT PRICE CALCULATION
  /// Mendapatkan daftar ingredient yang tersedia dari variable costs
  /// Menghitung harga per satuan dengan benar: Total Biaya ÷ Jumlah Bahan
  static List<Map<String, dynamic>> getAvailableIngredients(
      List<Map<String, dynamic>> variableCosts) {
    if (variableCosts.isEmpty) {
      print('📋 No variable costs available for ingredients');
      return [];
    }

    List<Map<String, dynamic>> validIngredients = [];

    for (var item in variableCosts) {
      try {
        final nama = item['nama']?.toString().trim() ?? '';
        final totalHarga = _safeParseDouble(item['totalHarga']);
        final jumlah = _safeParseDouble(item['jumlah']);
        final satuan =
            item['satuan']?.toString().trim() ?? AppConstants.defaultUnit;

        // Validate all required fields
        if (nama.isEmpty) {
          print('⚠️ Skipping ingredient with empty name');
          continue;
        }

        if (totalHarga <= 0) {
          print(
              '⚠️ Skipping ingredient $nama with invalid totalHarga: $totalHarga');
          continue;
        }

        if (jumlah <= 0) {
          print('⚠️ Skipping ingredient $nama with invalid jumlah: $jumlah');
          continue;
        }

        // FIXED: Calculate PROPER harga per satuan (unit price in the SAME unit as purchased)
        double hargaPerSatuan = totalHarga / jumlah;

        // Validate calculated price against constants
        if (hargaPerSatuan < AppConstants.minPrice ||
            hargaPerSatuan > AppConstants.maxPrice) {
          print(
              '⚠️ Skipping ingredient $nama with invalid calculated price: $hargaPerSatuan');
          continue;
        }

        // FIXED: Create properly structured ingredient data with ORIGINAL UNITS
        validIngredients.add({
          'nama': nama,
          'totalHarga': totalHarga, // Original total price
          'jumlah': jumlah, // Original quantity in purchased unit
          'satuan': satuan, // Original purchased unit (e.g., "Kilogram (kg)")
          'hargaPerSatuan': hargaPerSatuan, // Price per original unit
          'isValid': true,

          // FIXED: Add debugging info
          '_debug': {
            'calculation':
                '$totalHarga ÷ $jumlah $satuan = $hargaPerSatuan per $satuan',
            'originalData': item,
          },
        });

        print('✅ Added ingredient: $nama');
        print(
            '   Purchase: $jumlah $satuan @ ${formatRupiah(totalHarga)} total');
        print('   Unit price: ${formatRupiah(hargaPerSatuan)} per $satuan');
      } catch (e) {
        print('❌ Error processing ingredient ${item['nama']}: $e');
        continue;
      }
    }

    print(
        '✅ Processed ${validIngredients.length} valid ingredients from ${variableCosts.length} items');
    return validIngredients;
  }

  /// FIXED: Safe double parser with comprehensive error handling
  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;

    try {
      if (value is double) {
        return value.isFinite ? value : 0.0;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is num) {
        double parsed = value.toDouble();
        return parsed.isFinite ? parsed : 0.0;
      }
      if (value is String) {
        String cleaned = value.trim();
        if (cleaned.isEmpty) return 0.0;

        // Clean Rupiah formatting
        cleaned = cleaned.replaceAll(RegExp(r'[Rp\s,\.]'), '');
        if (cleaned.isEmpty) return 0.0;

        double? parsed = double.tryParse(cleaned);
        return (parsed != null && parsed.isFinite) ? parsed : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('❌ Error parsing double from: $value');
      return 0.0;
    }
  }

  /// Validasi apakah komposisi menu valid
  static bool isMenuCompositionValid(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return false;

    return komposisi.every((item) =>
        item.namaIngredient.trim().isNotEmpty &&
        item.namaIngredient.length <= AppConstants.maxTextLength &&
        item.jumlahDipakai >= AppConstants.minQuantity &&
        item.jumlahDipakai <= AppConstants.maxQuantity &&
        item.hargaPerSatuan >= AppConstants.minPrice &&
        item.hargaPerSatuan <= AppConstants.maxPrice);
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

    if (result.marginPercentage >= AppConstants.maxPercentage) {
      kategori = 'Premium';
      rekomendasi = 'Margin sangat tinggi, cocok untuk menu premium';
      status = 'excellent';
    } else if (result.marginPercentage >= 50) {
      kategori = 'Profit Tinggi';
      rekomendasi = 'Margin baik, menu menguntungkan';
      status = 'good';
    } else if (result.marginPercentage >= AppConstants.defaultMargin) {
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

  /// Method tambahan untuk membantu analisis menu
  static Map<String, dynamic> getMenuAnalysis(MenuCalculationResult result) {
    if (!result.isValid) {
      return {
        'isEfficient': false,
        'costBreakdown': {},
        'recommendations': [],
      };
    }

    Map<String, double> costBreakdown = {
      'bahanBaku': result.biayaBahanBakuMenu,
      'fixedCost': result.biayaFixedPerMenu,
      'operational': result.biayaOperationalPerMenu,
      'profit': result.profitPerMenu,
    };

    List<String> recommendations = [];

    double bahanBakuRatio =
        (result.biayaBahanBakuMenu / result.hppMurniPerMenu) * 100;
    if (bahanBakuRatio > 70) {
      recommendations.add('Pertimbangkan optimasi penggunaan bahan baku');
    }

    if (result.marginPercentage < AppConstants.defaultMargin) {
      recommendations.add(
          'Margin di bawah standar industri (${AppConstants.defaultMargin}%)');
    }

    return {
      'isEfficient': bahanBakuRatio <= 70 &&
          result.marginPercentage >= AppConstants.defaultMargin,
      'costBreakdown': costBreakdown,
      'recommendations': recommendations,
      'bahanBakuRatio': bahanBakuRatio,
    };
  }

  /// FIXED: Add debugging helper for troubleshooting unit calculations
  static Map<String, dynamic> debugCalculation({
    required String ingredientName,
    required double totalHarga,
    required double jumlah,
    required String satuan,
    required double usageAmount,
    required String usageUnit,
  }) {
    print('🔍 DEBUG CALCULATION for $ingredientName:');
    print('  Purchase: $jumlah $satuan @ ${formatRupiah(totalHarga)} total');

    double unitPrice = totalHarga / jumlah;
    print('  Unit price: ${formatRupiah(unitPrice)} per $satuan');

    print('  Usage: $usageAmount $usageUnit');

    // This is where unit conversion should happen
    if (satuan == usageUnit) {
      double cost = unitPrice * usageAmount;
      print('  Same units - Direct calculation: ${formatRupiah(cost)}');
      return {
        'method': 'direct',
        'cost': cost,
        'calculation':
            '$usageAmount $usageUnit × ${formatRupiah(unitPrice)} = ${formatRupiah(cost)}',
      };
    } else {
      print('  Different units - Need conversion: $satuan → $usageUnit');
      return {
        'method': 'conversion_needed',
        'cost': 0.0,
        'calculation': 'Unit conversion required from $satuan to $usageUnit',
      };
    }
  }
}
