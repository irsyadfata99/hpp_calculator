// lib/services/menu_calculator_service.dart - PHASE 1.5 FIX: Type Safety & Calculation Error Fix
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
  /// FIXED: Safe menu bahan baku cost calculation
  static double calculateMenuBahanBakuCost(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in komposisi) {
      try {
        // FIXED: Enhanced validation for MenuComposition
        if (item.namaIngredient.trim().isEmpty) continue;
        if (item.jumlahDipakai <= 0 || !item.jumlahDipakai.isFinite) continue;
        if (item.hargaPerSatuan <= 0 || !item.hargaPerSatuan.isFinite) continue;

        double cost = item.jumlahDipakai * item.hargaPerSatuan;
        if (cost.isFinite && cost > 0) {
          total += cost;
        }
      } catch (e) {
        continue; // Skip invalid items
      }
    }

    return total;
  }

  /// FIXED: Safe proportion calculation with division by zero protection
  static double calculateFixedCostProportion({
    required double biayaBahanBakuMenu,
    required double totalBiayaBahanBaku,
    required double biayaFixedPerPorsi,
  }) {
    if (totalBiayaBahanBaku <= 0 || biayaBahanBakuMenu <= 0) return 0.0;
    if (!biayaFixedPerPorsi.isFinite || biayaFixedPerPorsi < 0) return 0.0;

    try {
      double proportion = biayaBahanBakuMenu / totalBiayaBahanBaku;
      if (!proportion.isFinite || proportion < 0) return 0.0;

      double result = biayaFixedPerPorsi * proportion;
      return result.isFinite ? result : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// FIXED: Safe operational cost proportion calculation
  static double calculateOperationalCostProportion({
    required double biayaBahanBakuMenu,
    required double totalBiayaBahanBaku,
    required double operationalCostPerPorsi,
  }) {
    if (totalBiayaBahanBaku <= 0 || biayaBahanBakuMenu <= 0) return 0.0;
    if (!operationalCostPerPorsi.isFinite || operationalCostPerPorsi < 0)
      return 0.0;

    try {
      double proportion = biayaBahanBakuMenu / totalBiayaBahanBaku;
      if (!proportion.isFinite || proportion < 0) return 0.0;

      double result = operationalCostPerPorsi * proportion;
      return result.isFinite ? result : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// FIXED: Safe selling price calculation
  static double calculateSellingPrice({
    required double hppMurniPerMenu,
    required double marginPercentage,
  }) {
    if (!hppMurniPerMenu.isFinite || hppMurniPerMenu < 0) return 0.0;
    if (!marginPercentage.isFinite || marginPercentage < 0)
      return hppMurniPerMenu;

    try {
      double multiplier = 1 + (marginPercentage / 100);
      if (!multiplier.isFinite || multiplier <= 0) return hppMurniPerMenu;

      double result = hppMurniPerMenu * multiplier;
      return result.isFinite ? result : hppMurniPerMenu;
    } catch (e) {
      return hppMurniPerMenu;
    }
  }

  /// FIXED: Safe profit calculation
  static double calculateProfitPerMenu({
    required double hargaSetelahMargin,
    required double hppMurniPerMenu,
  }) {
    if (!hargaSetelahMargin.isFinite || !hppMurniPerMenu.isFinite) return 0.0;

    try {
      double profit = hargaSetelahMargin - hppMurniPerMenu;
      return profit.isFinite ? profit : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// FIXED: Enhanced menu cost calculation with comprehensive validation
  static MenuCalculationResult calculateMenuCost({
    required MenuItem menu,
    required SharedCalculationData sharedData,
    required double marginPercentage,
  }) {
    try {
      // FIXED: Enhanced input validation
      if (menu.komposisi.isEmpty) {
        return MenuCalculationResult.error(
            'Menu harus memiliki minimal 1 komposisi bahan');
      }

      if (!marginPercentage.isFinite ||
          marginPercentage < AppConstants.minPercentage ||
          marginPercentage > AppConstants.maxPercentage) {
        return MenuCalculationResult.error(
            'Margin harus antara ${AppConstants.minPercentage}% - ${AppConstants.maxPercentage}%');
      }

      // Validate each composition item
      for (int i = 0; i < menu.komposisi.length; i++) {
        final komposisi = menu.komposisi[i];

        if (komposisi.namaIngredient.trim().isEmpty) {
          return MenuCalculationResult.error(
              'Nama bahan ke-${i + 1} tidak boleh kosong');
        }

        if (komposisi.namaIngredient.length > AppConstants.maxTextLength) {
          return MenuCalculationResult.error(
              'Nama bahan ke-${i + 1} terlalu panjang');
        }

        if (!komposisi.jumlahDipakai.isFinite ||
            komposisi.jumlahDipakai <= 0 ||
            komposisi.jumlahDipakai > AppConstants.maxQuantity) {
          return MenuCalculationResult.error(
              'Jumlah bahan "${komposisi.namaIngredient}" tidak valid');
        }

        if (!komposisi.hargaPerSatuan.isFinite ||
            komposisi.hargaPerSatuan < AppConstants.minPrice ||
            komposisi.hargaPerSatuan > AppConstants.maxPrice) {
          return MenuCalculationResult.error(
              'Harga per satuan bahan "${komposisi.namaIngredient}" tidak valid');
        }
      }

      // FIXED: Safe calculation of menu bahan baku cost
      double biayaBahanBakuMenu = calculateMenuBahanBakuCost(menu.komposisi);
      if (biayaBahanBakuMenu <= 0) {
        return MenuCalculationResult.error('Biaya bahan baku menu tidak valid');
      }

      // FIXED: Safe calculation of total bahan baku from shared data
      double totalBiayaBahanBaku = 0.0;
      for (var item in sharedData.variableCosts) {
        try {
          final totalHarga = _safeParseDouble(item['totalHarga']);
          if (totalHarga != null && totalHarga > 0) {
            totalBiayaBahanBaku += totalHarga;
          }
        } catch (e) {
          continue;
        }
      }

      if (totalBiayaBahanBaku <= 0) {
        return MenuCalculationResult.error('Data bahan baku HPP tidak valid');
      }

      // FIXED: Safe calculation of fixed cost per menu
      double biayaFixedPerMenu = calculateFixedCostProportion(
        biayaBahanBakuMenu: biayaBahanBakuMenu,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        biayaFixedPerPorsi: sharedData.biayaFixedPerPorsi,
      );

      // FIXED: Safe calculation of operational cost per menu
      double operationalCostPerPorsi =
          sharedData.calculateOperationalCostPerPorsi();
      double biayaOperationalPerMenu = calculateOperationalCostProportion(
        biayaBahanBakuMenu: biayaBahanBakuMenu,
        totalBiayaBahanBaku: totalBiayaBahanBaku,
        operationalCostPerPorsi: operationalCostPerPorsi,
      );

      // FIXED: Safe calculation of HPP murni for menu
      double hppMurniPerMenu =
          biayaBahanBakuMenu + biayaFixedPerMenu + biayaOperationalPerMenu;

      if (!hppMurniPerMenu.isFinite || hppMurniPerMenu <= 0) {
        return MenuCalculationResult.error('HPP murni menu tidak valid');
      }

      // FIXED: Safe calculation of selling price with margin
      double hargaSetelahMargin = calculateSellingPrice(
        hppMurniPerMenu: hppMurniPerMenu,
        marginPercentage: marginPercentage,
      );

      // FIXED: Safe calculation of profit per menu
      double profitPerMenu = calculateProfitPerMenu(
        hargaSetelahMargin: hargaSetelahMargin,
        hppMurniPerMenu: hppMurniPerMenu,
      );

      // Final validation
      if (!hargaSetelahMargin.isFinite || !profitPerMenu.isFinite) {
        return MenuCalculationResult.error('Hasil perhitungan tidak valid');
      }

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

  /// FIXED: Enhanced getAvailableIngredients with proper unit price calculation
  static List<Map<String, dynamic>> getAvailableIngredients(
      List<Map<String, dynamic>> variableCosts) {
    if (variableCosts.isEmpty) {
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

        // FIXED: Enhanced validation
        if (nama.isEmpty || nama.length > AppConstants.maxTextLength) continue;
        if (totalHarga == null ||
            totalHarga <= 0 ||
            totalHarga > AppConstants.maxPrice) continue;
        if (jumlah == null || jumlah <= 0 || jumlah > AppConstants.maxQuantity)
          continue;

        // FIXED: Safe calculation of unit price
        double hargaPerSatuan = totalHarga / jumlah;
        if (!hargaPerSatuan.isFinite ||
            hargaPerSatuan < AppConstants.minPrice ||
            hargaPerSatuan > AppConstants.maxPrice) {
          continue;
        }

        // Create properly structured ingredient data
        validIngredients.add({
          'nama': nama,
          'totalHarga': totalHarga,
          'jumlah': jumlah,
          'satuan': satuan,
          'hargaPerSatuan': hargaPerSatuan,
          'isValid': true,
        });
      } catch (e) {
        continue; // Skip invalid items
      }
    }

    return validIngredients;
  }

  /// FIXED: Enhanced safe double parser
  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) {
        return value.isFinite ? value : null;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is num) {
        double parsed = value.toDouble();
        return parsed.isFinite ? parsed : null;
      }
      if (value is String) {
        String cleaned = value.trim();
        if (cleaned.isEmpty) return null;

        // FIXED: Enhanced string cleaning for Rupiah formatting
        cleaned = cleaned.replaceAll(RegExp(r'[Rp\s,\.]'), '');
        if (cleaned.isEmpty) return null;

        double? parsed = double.tryParse(cleaned);
        return (parsed != null && parsed.isFinite) ? parsed : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// FIXED: Enhanced menu composition validation
  static bool isMenuCompositionValid(List<MenuComposition> komposisi) {
    if (komposisi.isEmpty) return false;

    return komposisi.every((item) {
      try {
        return item.namaIngredient.trim().isNotEmpty &&
            item.namaIngredient.length <= AppConstants.maxTextLength &&
            item.jumlahDipakai.isFinite &&
            item.jumlahDipakai >= AppConstants.minQuantity &&
            item.jumlahDipakai <= AppConstants.maxQuantity &&
            item.hargaPerSatuan.isFinite &&
            item.hargaPerSatuan >= AppConstants.minPrice &&
            item.hargaPerSatuan <= AppConstants.maxPrice;
      } catch (e) {
        return false;
      }
    });
  }

  /// FIXED: Enhanced margin analysis
  static Map<String, dynamic> analyzeMenuMargin(MenuCalculationResult result) {
    if (!result.isValid) {
      return {
        'kategori': 'Invalid',
        'rekomendasi': 'Data tidak valid',
        'status': 'error',
        'isAvailable': false,
      };
    }

    try {
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

      double profitRatio = 0.0;
      if (result.hargaSetelahMargin > 0) {
        profitRatio = (result.profitPerMenu / result.hargaSetelahMargin) * 100;
      }

      return {
        'kategori': kategori,
        'rekomendasi': rekomendasi,
        'status': status,
        'profitRatio': profitRatio.isFinite ? profitRatio : 0.0,
        'isAvailable': true,
      };
    } catch (e) {
      return {
        'kategori': 'Error',
        'rekomendasi': 'Error dalam analisis: ${e.toString()}',
        'status': 'error',
        'isAvailable': false,
      };
    }
  }

  /// FIXED: Enhanced menu analysis
  static Map<String, dynamic> getMenuAnalysis(MenuCalculationResult result) {
    if (!result.isValid) {
      return {
        'isEfficient': false,
        'costBreakdown': <String, double>{},
        'recommendations': <String>[],
        'isAvailable': false,
      };
    }

    try {
      Map<String, double> costBreakdown = {
        'bahanBaku': result.biayaBahanBakuMenu,
        'fixedCost': result.biayaFixedPerMenu,
        'operational': result.biayaOperationalPerMenu,
        'profit': result.profitPerMenu,
      };

      List<String> recommendations = [];

      if (result.hppMurniPerMenu > 0) {
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
          'bahanBakuRatio': bahanBakuRatio.isFinite ? bahanBakuRatio : 0.0,
          'isAvailable': true,
        };
      }

      return {
        'isEfficient': false,
        'costBreakdown': costBreakdown,
        'recommendations': ['Data HPP tidak valid'],
        'bahanBakuRatio': 0.0,
        'isAvailable': false,
      };
    } catch (e) {
      return {
        'isEfficient': false,
        'costBreakdown': <String, double>{},
        'recommendations': ['Error dalam analisis: ${e.toString()}'],
        'isAvailable': false,
      };
    }
  }
}
