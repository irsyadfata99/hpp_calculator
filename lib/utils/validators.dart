// lib/utils/validators.dart - FIXED VERSION (Bug CB-007 & #18 Resolved + Missing Methods Added)

import 'constants.dart';
import 'dart:math' as math;

class InputValidator {
  // 🔧 FIXED CB-007: Added comprehensive edge cases
  // 🔧 FIXED #18: Standardized all validation approaches
  // 🔧 FIXED: Added missing validateSalaryDirect method

  /// Validate name input dengan context Indonesia UMKM - ENHANCED
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.errorEmptyName;
    }

    String trimmed = value.trim();

    if (trimmed.length > AppConstants.maxTextLength) {
      return 'Nama terlalu panjang (maksimal ${AppConstants.maxTextLength} karakter)';
    }

    // 🆕 EDGE CASE: Check for whitespace-only names
    if (trimmed.replaceAll(RegExp(r'\s+'), '').isEmpty) {
      return 'Nama tidak boleh hanya berisi spasi';
    }

    // Enhanced invalid characters check
    if (trimmed.contains('<') ||
        trimmed.contains('>') ||
        trimmed.contains('"') ||
        trimmed.contains("'") ||
        trimmed.contains('\\') ||
        trimmed.contains('/')) {
      return 'Nama mengandung karakter yang tidak diizinkan';
    }

    // Business validation untuk nama produk/karyawan Indonesia
    if (trimmed.length < 2) {
      return 'Nama terlalu pendek (minimal 2 karakter)';
    }

    // 🆕 EDGE CASE: Check for repeated characters (like "aaaaa")
    if (_isRepeatedChars(trimmed)) {
      return 'Nama tidak boleh hanya terdiri dari karakter yang sama';
    }

    // 🆕 EDGE CASE: Check for numbers-only names
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Nama tidak boleh hanya berisi angka';
    }

    return null;
  }

  /// Validate price dengan context UMKM Indonesia (Rupiah) - STANDARDIZED
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga tidak boleh kosong';
    }

    // 🔧 STANDARDIZED: Use common cleaning method
    String cleanValue = _cleanNumericInput(value);

    // 🆕 EDGE CASE: Check for empty after cleaning
    if (cleanValue.isEmpty) {
      return 'Harga harus berisi angka yang valid';
    }

    double? price = double.tryParse(cleanValue);
    if (price == null) {
      return AppConstants.errorInvalidPrice;
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (price.isNaN || price.isInfinite) {
      return 'Harga tidak boleh berisi nilai tidak valid (NaN/Infinity)';
    }

    if (price < AppConstants.minPrice) {
      return AppConstants.errorNegativePrice;
    }

    if (price > AppConstants.maxPrice) {
      return AppConstants.errorMaxPrice;
    }

    // 🆕 EDGE CASE: Check for too many decimal places
    if (_hasExcessiveDecimals(cleanValue)) {
      return 'Harga tidak boleh memiliki lebih dari 2 angka desimal';
    }

    return null;
  }

  /// Validate salary dengan UMR Indonesia context - STANDARDIZED
  static String? validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gaji tidak boleh kosong';
    }

    // 🔧 STANDARDIZED: Use common cleaning method
    String cleanValue = _cleanNumericInput(value);

    if (cleanValue.isEmpty) {
      return 'Gaji harus berisi angka yang valid';
    }

    double? salary = double.tryParse(cleanValue);
    if (salary == null) {
      return 'Gaji harus berupa angka yang valid';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (salary.isNaN || salary.isInfinite) {
      return 'Gaji tidak boleh berisi nilai tidak valid';
    }

    if (salary < AppConstants.minSalary) {
      return AppConstants.errorLowSalary;
    }

    if (salary > AppConstants.maxSalary) {
      return AppConstants.errorHighSalary;
    }

    // 🆕 EDGE CASE: Check realistic salary ranges untuk Indonesia
    if (salary < 1000000 && salary >= AppConstants.minSalary) {
      // Warning untuk gaji di bawah UMR terendah Indonesia
      // Return warning, tapi tetap valid (mungkin part-time)
    }

    return null;
  }

  /// 🆕 ADDED: Validate salary direct input (for direct double input) - NEW METHOD
  static String? validateSalaryDirect(double? salary) {
    if (salary == null) {
      return 'Gaji tidak boleh kosong';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (salary.isNaN || salary.isInfinite) {
      return 'Gaji tidak boleh berisi nilai tidak valid';
    }

    if (salary < AppConstants.minSalary) {
      return AppConstants.errorLowSalary;
    }

    if (salary > AppConstants.maxSalary) {
      return AppConstants.errorHighSalary;
    }

    // 🆕 EDGE CASE: Check realistic salary ranges untuk Indonesia
    if (salary < 1000000 && salary >= AppConstants.minSalary) {
      // Warning untuk gaji di bawah UMR terendah Indonesia
      // Return warning, tapi tetap valid (mungkin part-time)
    }

    return null;
  }

  /// 🆕 ADDED: Validate price direct input (for direct double input) - NEW METHOD
  static String? validatePriceDirect(double? price) {
    if (price == null) {
      return 'Harga tidak boleh kosong';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (price.isNaN || price.isInfinite) {
      return 'Harga tidak boleh berisi nilai tidak valid (NaN/Infinity)';
    }

    if (price < AppConstants.minPrice) {
      return AppConstants.errorNegativePrice;
    }

    if (price > AppConstants.maxPrice) {
      return AppConstants.errorMaxPrice;
    }

    return null;
  }

  /// 🆕 ADDED: Validate quantity direct input (for direct double input) - NEW METHOD
  static String? validateQuantityDirect(double? quantity) {
    if (quantity == null) {
      return 'Jumlah tidak boleh kosong';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (quantity.isNaN || quantity.isInfinite) {
      return 'Jumlah tidak boleh berisi nilai tidak valid';
    }

    if (quantity <= 0) {
      return AppConstants.errorZeroQuantity;
    }

    if (quantity > AppConstants.maxQuantity) {
      return 'Jumlah terlalu besar (maksimal ${AppConstants.maxQuantity.toStringAsFixed(0)})';
    }

    return null;
  }

  /// 🆕 ADDED: Validate percentage direct input (for direct double input) - NEW METHOD
  static String? validatePercentageDirect(double? percentage) {
    if (percentage == null) {
      return 'Persentase tidak boleh kosong';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (percentage.isNaN || percentage.isInfinite) {
      return 'Persentase tidak boleh berisi nilai tidak valid';
    }

    if (percentage < AppConstants.minPercentage) {
      return 'Persentase harus lebih dari 0%';
    }

    if (percentage > AppConstants.maxPercentage) {
      return AppConstants.errorInvalidPercentage;
    }

    // 🆕 EDGE CASE: Business logic validation
    if (percentage > 1000) {
      return 'Persentase terlalu besar - periksa kembali input Anda';
    }

    return null;
  }

  /// Validate quantity dengan context UMKM Indonesia - ENHANCED
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }

    // 🔧 STANDARDIZED: Use common cleaning method
    String cleanValue = _cleanNumericInput(value);

    if (cleanValue.isEmpty) {
      return 'Jumlah harus berisi angka yang valid';
    }

    double? quantity = double.tryParse(cleanValue);
    if (quantity == null) {
      return AppConstants.errorInvalidQuantity;
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (quantity.isNaN || quantity.isInfinite) {
      return 'Jumlah tidak boleh berisi nilai tidak valid';
    }

    if (quantity <= 0) {
      return AppConstants.errorZeroQuantity;
    }

    if (quantity > AppConstants.maxQuantity) {
      return 'Jumlah terlalu besar (maksimal ${AppConstants.maxQuantity.toStringAsFixed(0)})';
    }

    // 🆕 EDGE CASE: Check for excessive precision
    if (_hasExcessivePrecision(cleanValue, 3)) {
      return 'Jumlah tidak boleh memiliki lebih dari 3 angka desimal';
    }

    return null;
  }

  /// Validate percentage dengan business context - ENHANCED
  static String? validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Persentase tidak boleh kosong';
    }

    // 🔧 STANDARDIZED: Use common cleaning method
    String cleanValue = _cleanPercentageInput(value);

    if (cleanValue.isEmpty) {
      return 'Persentase harus berisi angka yang valid';
    }

    double? percentage = double.tryParse(cleanValue);
    if (percentage == null) {
      return 'Persentase harus berupa angka';
    }

    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (percentage.isNaN || percentage.isInfinite) {
      return 'Persentase tidak boleh berisi nilai tidak valid';
    }

    if (percentage < AppConstants.minPercentage) {
      return 'Persentase harus lebih dari 0%';
    }

    if (percentage > AppConstants.maxPercentage) {
      return AppConstants.errorInvalidPercentage;
    }

    // 🆕 EDGE CASE: Business logic validation
    if (percentage > 1000) {
      return 'Persentase terlalu besar - periksa kembali input Anda';
    }

    return null;
  }

  /// Validate margin dengan business logic Indonesia UMKM - ENHANCED
  static String? validateMargin(double margin) {
    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (margin.isNaN || margin.isInfinite) {
      return 'Margin tidak boleh berisi nilai tidak valid';
    }

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

    // 🆕 EDGE CASE: Warning untuk margin yang tidak realistis
    if (margin > 500) {
      return 'Margin terlalu tinggi - mungkin tidak kompetitif di pasar';
    }

    return null;
  }

  /// Validate business estimations untuk UMKM Indonesia - ENHANCED
  static String? validateEstimation(double value, String type) {
    // 🆕 EDGE CASE: Check for NaN or Infinity
    if (value.isNaN || value.isInfinite) {
      return '$type tidak boleh berisi nilai tidak valid';
    }

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
        // 🆕 EDGE CASE: Check for decimal porsi
        if (value != value.floor() && value < 10) {
          return 'Porsi kurang dari 10 sebaiknya bilangan bulat';
        }
        break;

      case 'produksi':
        if (value > 31) {
          return 'Produksi per bulan maksimal 31 hari';
        }
        if (value < 1) {
          return 'Minimal 1 hari produksi per bulan';
        }
        // 🆕 EDGE CASE: Check for fractional production days
        if (value != value.floor()) {
          return 'Hari produksi sebaiknya bilangan bulat';
        }
        break;
    }

    return null;
  }

  /// Business logic validation untuk HPP calculation - ENHANCED
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

    // 🆕 EDGE CASE: Check for NaN values in inputs
    if (estimasiPorsi.isNaN || estimasiProduksi.isNaN) {
      warnings['calculation'] = 'Ada nilai tidak valid dalam perhitungan';
      return warnings;
    }

    // Check realistic production
    double totalPorsi = estimasiPorsi * estimasiProduksi;
    if (totalPorsi > 10000) {
      warnings['production'] =
          'Total produksi bulanan sangat besar (${totalPorsi.toStringAsFixed(0)} porsi). Pastikan realistis.';
    }

    // 🆕 EDGE CASE: Check for too small production
    if (totalPorsi < 10) {
      warnings['productionLow'] =
          'Produksi bulanan sangat kecil (${totalPorsi.toStringAsFixed(0)} porsi). Pastikan menguntungkan.';
    }

    // Check operational cost ratio
    if (totalOperational != null && hppResult != null && hppResult > 0) {
      if (totalOperational.isNaN || hppResult.isNaN) {
        warnings['operationalCalc'] =
            'Ada nilai tidak valid dalam biaya operasional';
      } else {
        double operationalRatio = (totalOperational / hppResult) * 100;
        if (operationalRatio > AppConstants.maxOperationalRatio) {
          warnings['operational'] = AppConstants.warningHighOperational;
        }

        // 🆕 EDGE CASE: Check for negative operational costs
        if (totalOperational < 0) {
          warnings['operationalNegative'] =
              'Biaya operasional tidak boleh negatif';
        }
      }
    }

    // 🆕 EDGE CASE: Validate individual variable costs
    double totalVariableCost = 0;
    for (var cost in variableCosts) {
      double? itemCost = cost['totalHarga']?.toDouble();
      if (itemCost != null) {
        if (itemCost.isNaN || itemCost.isInfinite) {
          warnings['variableCostInvalid'] =
              'Ada harga bahan yang tidak valid: ${cost['nama']}';
          break;
        }
        totalVariableCost += itemCost;
      }
    }

    if (totalVariableCost <= 0 && variableCosts.isNotEmpty) {
      warnings['variableCostZero'] = 'Total biaya bahan baku tidak boleh nol';
    }

    return warnings;
  }

  /// Validate menu composition untuk restaurant/warung - ENHANCED
  static String? validateMenuComposition(List<dynamic> composition) {
    if (composition.isEmpty) {
      return 'Menu harus memiliki minimal 1 bahan';
    }

    if (composition.length > 20) {
      return 'Komposisi menu terlalu kompleks (maksimal 20 bahan)';
    }

    // 🆕 EDGE CASE: Check for duplicate ingredients
    Set<String> uniqueIngredients = <String>{};
    for (var item in composition) {
      if (item is Map<String, dynamic> && item['namaIngredient'] != null) {
        String nama = item['namaIngredient'].toString().toLowerCase().trim();
        if (uniqueIngredients.contains(nama)) {
          return 'Ada bahan yang duplikat dalam komposisi: ${item['namaIngredient']}';
        }
        uniqueIngredients.add(nama);
      }
    }

    return null;
  }

  /// Validate competitive pricing untuk market context Indonesia - ENHANCED
  static Map<String, dynamic> validateCompetitivePricing({
    required double hargaJual,
    required String businessType,
  }) {
    Map<String, dynamic> analysis = {
      'isCompetitive': true,
      'warning': null,
      'suggestion': null,
    };

    // 🆕 EDGE CASE: Check for invalid price first
    if (hargaJual.isNaN || hargaJual.isInfinite || hargaJual <= 0) {
      analysis['isCompetitive'] = false;
      analysis['warning'] = 'Harga jual tidak valid';
      analysis['suggestion'] = 'Periksa kembali perhitungan harga';
      return analysis;
    }

    // Indonesian UMKM market price ranges (updated 2024)
    Map<String, Map<String, double>> marketRanges = {
      'warung makan': {'min': 15000, 'max': 75000},
      'katering': {'min': 25000, 'max': 150000},
      'konveksi': {'min': 30000, 'max': 300000},
      'toko kue': {'min': 5000, 'max': 200000},
      'laundry': {'min': 3000, 'max': 35000},
      'minuman': {'min': 3000, 'max': 50000},
      'snack': {'min': 2000, 'max': 25000},
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
              'Pertimbangkan menaikkan harga atau review efisiensi';
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

  /// Clean numeric input (remove Rupiah formatting) - STANDARDIZED
  static String cleanNumericInput(String input) {
    return _cleanNumericInput(input);
  }

  /// 🔧 PRIVATE HELPER METHODS - STANDARDIZED

  /// Consistent numeric cleaning across all validators
  static String _cleanNumericInput(String input) {
    // Remove Rupiah formatting, spaces, and non-numeric except decimal point
    return input.replaceAll(RegExp(r'[^\d\.]'), '');
  }

  /// Clean percentage input
  static String _cleanPercentageInput(String input) {
    // Remove % symbol and other formatting
    return input.replaceAll(RegExp(r'[^\d\.]'), '');
  }

  /// Check if string is repeated characters (aaaa, 1111, etc)
  static bool _isRepeatedChars(String input) {
    if (input.length < 3) return false;

    String first = input[0];
    for (int i = 1; i < input.length; i++) {
      if (input[i] != first) return false;
    }
    return true;
  }

  /// Check if number has excessive decimal places
  static bool _hasExcessiveDecimals(String input, [int maxDecimals = 2]) {
    if (!input.contains('.')) return false;

    List<String> parts = input.split('.');
    if (parts.length != 2) return false;

    return parts[1].length > maxDecimals;
  }

  /// Check if number has excessive precision
  static bool _hasExcessivePrecision(String input, int maxDecimals) {
    return _hasExcessiveDecimals(input, maxDecimals);
  }

  /// Format input untuk display yang user-friendly - ENHANCED
  static String formatInputForDisplay(String input, String type) {
    try {
      switch (type.toLowerCase()) {
        case 'rupiah':
          String clean = _cleanNumericInput(input);
          double? value = double.tryParse(clean);
          if (value != null && !value.isNaN && value.isFinite) {
            return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]}.',
                )}';
          }
          break;
        case 'percentage':
          String clean = _cleanPercentageInput(input);
          double? value = double.tryParse(clean);
          if (value != null && !value.isNaN && value.isFinite) {
            return '${value.toStringAsFixed(1)}%';
          }
          break;
        case 'decimal':
          String clean = _cleanNumericInput(input);
          double? value = double.tryParse(clean);
          if (value != null && !value.isNaN && value.isFinite) {
            return value.toStringAsFixed(2);
          }
          break;
      }
    } catch (e) {
      // Return original input if formatting fails
      return input;
    }
    return input;
  }

  /// Validate complete UMKM business setup - ENHANCED
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

    // 🆕 EDGE CASE: Check for NaN values in estimations
    if (estimasiPorsi.isNaN || estimasiProduksi.isNaN) {
      validation['estimation'] = 'Ada nilai estimasi yang tidak valid';
      return validation;
    }

    // Bahan baku
    if (variableCosts.isEmpty) {
      validation['variableCosts'] = 'UMKM harus memiliki data bahan baku';
    } else {
      // 🆕 EDGE CASE: Validate each variable cost item
      for (int i = 0; i < variableCosts.length; i++) {
        var cost = variableCosts[i];
        if (cost['totalHarga'] == null || cost['totalHarga'] <= 0) {
          validation['variableCosts'] =
              'Ada bahan dengan harga tidak valid: ${cost['nama'] ?? 'Unknown'}';
          break;
        }
      }
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

    // 🆕 EDGE CASE: Overall business viability check
    double totalPorsi = estimasiPorsi * estimasiProduksi;
    double avgVariableCost = variableCosts.fold(
            0.0, (sum, cost) => sum + (cost['totalHarga']?.toDouble() ?? 0)) /
        math.max(variableCosts.length, 1);

    if (totalPorsi < 30 && avgVariableCost > 50000) {
      validation['viability'] =
          'Dengan produksi rendah dan biaya tinggi, pastikan margin mencukupi';
    }

    return validation;
  }

  /// 🆕 NEW: Validate calculator inputs for edge cases
  static String? validateCalculatorInput({
    required double dividend,
    required double divisor,
    String? context,
  }) {
    if (dividend.isNaN || divisor.isNaN) {
      return '${context ?? 'Perhitungan'} mengandung nilai tidak valid (NaN)';
    }

    if (dividend.isInfinite || divisor.isInfinite) {
      return '${context ?? 'Perhitungan'} mengandung nilai tak hingga (Infinity)';
    }

    if (divisor == 0) {
      return '${context ?? 'Pembagi'} tidak boleh nol';
    }

    if (divisor.abs() < 0.000001) {
      return '${context ?? 'Pembagi'} terlalu kecil, hasil mungkin tidak akurat';
    }

    return null;
  }

  /// 🆕 ADDED: Additional utility methods yang mungkin diperlukan

  /// Validate email format (jika diperlukan untuk UMKM)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email opsional
    }

    String trimmed = value.trim();

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validate phone number Indonesia format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone opsional
    }

    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Indonesian phone number patterns
    if (cleaned.startsWith('+62')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('62')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.length < 8 || cleaned.length > 13) {
      return 'Nomor telepon tidak valid (8-13 digit)';
    }

    return null;
  }

  /// Validate Indonesian currency input (Rupiah)
  static String? validateRupiah(String? value) {
    return validatePrice(value);
  }

  /// Validate tax percentage untuk Indonesia (PPN, dll)
  static String? validateTaxPercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Tax opsional
    }

    String? result = validatePercentage(value);
    if (result != null) return result;

    double? tax = double.tryParse(_cleanPercentageInput(value));
    if (tax != null && tax > 100) {
      return 'Persentase pajak tidak boleh lebih dari 100%';
    }

    return null;
  }
}
