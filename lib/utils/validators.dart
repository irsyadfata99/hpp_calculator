// lib/utils/validators.dart - TAHAP 3 IMPROVED VERSION
import 'constants.dart';

class InputValidator {
  /// Validate name input dengan context Indonesia UMKM
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.errorEmptyName;
    }

    String trimmed = value.trim();

    if (trimmed.length > AppConstants.maxTextLength) {
      return 'Nama terlalu panjang (maksimal ${AppConstants.maxTextLength} karakter)';
    }

    // Check for invalid characters
    if (trimmed.contains('<') ||
        trimmed.contains('>') ||
        trimmed.contains('"')) {
      return 'Nama mengandung karakter yang tidak diizinkan';
    }

    // Business validation untuk nama produk/karyawan Indonesia
    if (trimmed.length < 2) {
      return 'Nama terlalu pendek (minimal 2 karakter)';
    }

    return null;
  }

  /// Validate price dengan context UMKM Indonesia (Rupiah)
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga tidak boleh kosong';
    }

    // Remove currency formatting if present (Rp, titik, koma, spasi)
    String cleanValue = value.replaceAll(RegExp(r'[Rp\.,\s]'), '');

    double? price = double.tryParse(cleanValue);
    if (price == null) {
      return AppConstants.errorInvalidPrice;
    }

    if (price < AppConstants.minPrice) {
      return AppConstants.errorNegativePrice;
    }

    if (price > AppConstants.maxPrice) {
      return AppConstants.errorMaxPrice;
    }

    return null;
  }

  /// Validate salary dengan UMR Indonesia context
  static String? validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gaji tidak boleh kosong';
    }

    // Remove currency formatting
    String cleanValue = value.replaceAll(RegExp(r'[Rp\.,\s]'), '');

    double? salary = double.tryParse(cleanValue);
    if (salary == null) {
      return 'Gaji harus berupa angka yang valid';
    }

    if (salary < AppConstants.minSalary) {
      return AppConstants.errorLowSalary;
    }

    if (salary > AppConstants.maxSalary) {
      return AppConstants.errorHighSalary;
    }

    return null;
  }

  /// Validate quantity dengan context UMKM Indonesia
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }

    double? quantity = double.tryParse(value);
    if (quantity == null) {
      return AppConstants.errorInvalidQuantity;
    }

    if (quantity <= 0) {
      return AppConstants.errorZeroQuantity;
    }

    if (quantity > AppConstants.maxQuantity) {
      return 'Jumlah terlalu besar (maksimal ${AppConstants.maxQuantity.toStringAsFixed(0)})';
    }

    return null;
  }

  /// Validate percentage dengan business context
  static String? validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Persentase tidak boleh kosong';
    }

    // Remove % symbol if present
    String cleanValue = value.replaceAll('%', '').trim();

    double? percentage = double.tryParse(cleanValue);
    if (percentage == null) {
      return 'Persentase harus berupa angka';
    }

    if (percentage < AppConstants.minPercentage) {
      return 'Persentase harus lebih dari 0%';
    }

    if (percentage > AppConstants.maxPercentage) {
      return AppConstants.errorInvalidPercentage;
    }

    return null;
  }

  /// Validate margin dengan business logic Indonesia UMKM
  static String? validateMargin(double margin) {
    if (margin < AppConstants.minPercentage) {
      return 'Margin harus lebih dari 0%';
    }

    if (margin > AppConstants.maxPercentage) {
      return AppConstants.errorInvalidPercentage;
    }

    // Business warning untuk margin terlalu rendah
    if (margin < AppConstants.minMarginWarning) {
      return AppConstants.warningLowMargin;
    }

    return null;
  }

  /// Validate business estimations untuk UMKM Indonesia
  static String? validateEstimation(double value, String type) {
    if (value <= 0) {
      return '$type harus lebih dari 0';
    }

    switch (type.toLowerCase()) {
      case 'porsi':
        if (value > 1000) {
          return 'Estimasi porsi per produksi terlalu besar (maksimal 1000)';
        }
        if (value < 1) {
          return 'Estimasi porsi minimal 1';
        }
        break;

      case 'produksi':
        if (value > 31) {
          return 'Produksi per bulan maksimal 31 hari';
        }
        if (value < 1) {
          return 'Minimal 1 hari produksi per bulan';
        }
        break;
    }

    return null;
  }

  /// Business logic validation untuk HPP calculation
  static Map<String, String?> validateHPPCalculation({
    required List<Map<String, dynamic>> variableCosts,
    required double estimasiPorsi,
    required double estimasiProduksi,
    double? totalOperational,
    double? hppResult,
  }) {
    Map<String, String?> warnings = {};

    // Check if bahan baku ada
    if (variableCosts.isEmpty) {
      warnings['variableCosts'] =
          'Belum ada data bahan baku. Tambahkan minimal 1 bahan.';
    }

    // Check realistic production
    double totalPorsi = estimasiPorsi * estimasiProduksi;
    if (totalPorsi > 10000) {
      warnings['production'] =
          'Total produksi bulanan sangat besar (${totalPorsi.toStringAsFixed(0)} porsi). Pastikan realistis.';
    }

    // Check operational cost ratio
    if (totalOperational != null && hppResult != null && hppResult > 0) {
      double operationalRatio = (totalOperational / hppResult) * 100;
      if (operationalRatio > AppConstants.maxOperationalRatio) {
        warnings['operational'] = AppConstants.warningHighOperational;
      }
    }

    return warnings;
  }

  /// Validate menu composition untuk restaurant/warung
  static String? validateMenuComposition(List<dynamic> composition) {
    if (composition.isEmpty) {
      return 'Menu harus memiliki minimal 1 bahan';
    }

    if (composition.length > 20) {
      return 'Komposisi menu terlalu kompleks (maksimal 20 bahan)';
    }

    return null;
  }

  /// Validate competitive pricing untuk market context Indonesia
  static Map<String, dynamic> validateCompetitivePricing({
    required double hargaJual,
    required String businessType,
  }) {
    Map<String, dynamic> analysis = {
      'isCompetitive': true,
      'warning': null,
      'suggestion': null,
    };

    // Indonesian UMKM market price ranges (rough estimates)
    Map<String, Map<String, double>> marketRanges = {
      'warung makan': {'min': 15000, 'max': 50000},
      'katering': {'min': 20000, 'max': 100000},
      'konveksi': {'min': 25000, 'max': 200000},
      'toko kue': {'min': 5000, 'max': 150000},
      'laundry': {'min': 3000, 'max': 25000},
    };

    String lowerType = businessType.toLowerCase();
    for (String type in marketRanges.keys) {
      if (lowerType.contains(type)) {
        double min = marketRanges[type]!['min']!;
        double max = marketRanges[type]!['max']!;

        if (hargaJual < min) {
          analysis['isCompetitive'] = false;
          analysis['warning'] = 'Harga terlalu rendah untuk kategori $type';
          analysis['suggestion'] =
              'Pertimbangkan menaikkan harga atau review biaya';
        } else if (hargaJual > max) {
          analysis['isCompetitive'] = false;
          analysis['warning'] = 'Harga terlalu tinggi untuk kategori $type';
          analysis['suggestion'] =
              'Review efisiensi produksi atau target market premium';
        }
        break;
      }
    }

    return analysis;
  }

  /// Clean numeric input (remove Rupiah formatting)
  static String cleanNumericInput(String input) {
    return input.replaceAll(RegExp(r'[^\d\.]'), '');
  }

  /// Format input untuk display yang user-friendly
  static String formatInputForDisplay(String input, String type) {
    switch (type.toLowerCase()) {
      case 'rupiah':
        String clean = cleanNumericInput(input);
        double? value = double.tryParse(clean);
        if (value != null) {
          return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )}';
        }
        break;
      case 'percentage':
        return '$input%';
    }
    return input;
  }

  /// Validate complete UMKM business setup
  static Map<String, String?> validateCompleteUMKMSetup({
    required String businessName,
    required List<Map<String, dynamic>> variableCosts,
    required List<Map<String, dynamic>> fixedCosts,
    required List<dynamic> karyawan,
    required double estimasiPorsi,
    required double estimasiProduksi,
  }) {
    Map<String, String?> validation = {};

    // Business name
    validation['businessName'] = validateName(businessName);

    // Bahan baku
    if (variableCosts.isEmpty) {
      validation['variableCosts'] = 'UMKM harus memiliki data bahan baku';
    }

    // Fixed costs (opsional tapi disarankan)
    if (fixedCosts.isEmpty) {
      validation['fixedCosts'] =
          'Disarankan menambahkan biaya tetap (sewa, listrik, dll)';
    }

    // Karyawan (opsional untuk UMKM kecil)
    if (karyawan.isEmpty) {
      validation['karyawan'] =
          'Info: Belum ada data karyawan (OK untuk usaha sendiri)';
    }

    // Production estimation
    validation['estimasiPorsi'] = validateEstimation(estimasiPorsi, 'porsi');
    validation['estimasiProduksi'] =
        validateEstimation(estimasiProduksi, 'produksi');

    return validation;
  }
}
