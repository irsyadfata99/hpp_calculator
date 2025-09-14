// lib/services/universal_unit_service.dart - FIXED VERSION

import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class UniversalUnitService {
  // FIXED: Separate maps for unit info and conversion multipliers
  static final Map<String, String> _unitBaseTypes = {
    // Weight units
    'Ton': 'gram',
    'Kuintal': 'gram',
    'Kilogram (kg)': 'gram',
    'Gram (gr)': 'gram',
    'Ons': 'gram',

    // Volume units
    'Liter (L)': 'ml',
    'Mililiter (ml)': 'ml',

    // Length units
    'Meter (m)': 'cm',
    'Centimeter (cm)': 'cm',

    // Piece units
    'pcs (pieces)': 'pieces',
    'unit': 'pieces',
    'Pack': 'pieces',
    'Lusin': 'pieces',
    'Gross': 'pieces',
  };

  static final Map<String, double> _unitMultipliers = {
    // Weight conversions (to grams as base)
    'Ton': 1000000.0,
    'Kuintal': 100000.0,
    'Kilogram (kg)': 1000.0,
    'Gram (gr)': 1.0,
    'Ons': 100.0,

    // Volume conversions (to ml as base)
    'Liter (L)': 1000.0,
    'Mililiter (ml)': 1.0,

    // Length conversions (to cm as base)
    'Meter (m)': 100.0,
    'Centimeter (cm)': 1.0,

    // Piece units (no conversion needed)
    'pcs (pieces)': 1.0,
    'unit': 1.0,
    'Pack': 1.0,
    'Lusin': 12.0,
    'Gross': 144.0,
  };

  /// Units untuk belanja bahan (HPP Calculator) - FIXED
  static List<String> getPackageUnits() {
    return [
      'unit', // ✅ FIXED: Added default unit
      'pcs (pieces)', // ✅ FIXED: Added pieces
      'Kilogram (kg)',
      'Ton',
      'Kuintal',
      'Liter (L)',
      'Lusin',
      'Gross',
      'Meter (m)',
      'Pack',
    ];
  }

  /// Units untuk komposisi menu (Menu Calculator) - sesuai permintaan user
  static List<String> getUsageUnits() {
    return [
      AppConstants.defaultUsageUnit, // % (Persentase)
      'Gram (gr)', // ✅ Most common for cooking
      'Mililiter (ml)', // ✅ Most common for liquids
      'Centimeter (cm)', // For fabrics
      'pcs (pieces)', // For countable items
      'Kilogram (kg)',
      'Ons',
    ];
  }

  /// FIXED: Smart unit conversion calculation
  static CalculationResult calculateConvertedUnitCost({
    required double totalPrice,
    required double packageQuantity,
    required String packageUnit,
    required double unitsUsed,
    required String usageUnit,
  }) {
    try {
      // Validate inputs
      final priceValidation =
          InputValidator.validatePrice(totalPrice.toString());
      if (priceValidation != null) {
        return CalculationResult.error('Total harga: $priceValidation');
      }

      // Check if conversion is needed
      if (packageUnit == usageUnit) {
        // No conversion needed - direct calculation
        return calculateUnitCost(
          totalPrice: totalPrice,
          packageQuantity: packageQuantity,
          unitsUsed: unitsUsed,
        );
      }

      // Check if units are convertible
      if (!_areUnitsConvertible(packageUnit, usageUnit)) {
        return CalculationResult.error(
            'Cannot convert from $packageUnit to $usageUnit - different unit types');
      }

      // Convert package quantity to usage unit
      double convertedPackageQuantity = _convertUnits(
        value: packageQuantity,
        fromUnit: packageUnit,
        toUnit: usageUnit,
      );

      if (convertedPackageQuantity <= 0) {
        return CalculationResult.error('Unit conversion failed');
      }

      // Calculate cost with converted units
      double pricePerUsageUnit = totalPrice / convertedPackageQuantity;
      double totalCost = pricePerUsageUnit * unitsUsed;

      // Validate result
      if (totalCost > AppConstants.maxPrice) {
        return CalculationResult.error('Hasil perhitungan terlalu besar');
      }

      return CalculationResult.success(
        cost: totalCost,
        calculation:
            '${AppFormatters.formatRupiah(totalPrice)} ÷ ${convertedPackageQuantity.toStringAsFixed(3)} $usageUnit × ${unitsUsed.toStringAsFixed(3)} $usageUnit = ${AppFormatters.formatRupiah(totalCost)}',
        unitUsed: '$unitsUsed $usageUnit (dari $packageQuantity $packageUnit)',
      );
    } catch (e) {
      return CalculationResult.error('Error in calculation: ${e.toString()}');
    }
  }

  /// Check if two units can be converted
  static bool _areUnitsConvertible(String unit1, String unit2) {
    if (unit1 == unit2) return true;

    var unit1BaseType = _unitBaseTypes[unit1];
    var unit2BaseType = _unitBaseTypes[unit2];

    if (unit1BaseType == null || unit2BaseType == null) return false;

    // Units are convertible if they have the same base type
    return unit1BaseType == unit2BaseType;
  }

  /// Convert value from one unit to another
  static double _convertUnits({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return value;

    var fromMultiplier = _unitMultipliers[fromUnit];
    var toMultiplier = _unitMultipliers[toUnit];

    if (fromMultiplier == null || toMultiplier == null) {
      // Use logging framework instead of print in production
      debugPrint('❌ Unknown units: $fromUnit -> $toUnit');
      return 0.0;
    }

    var fromBaseType = _unitBaseTypes[fromUnit];
    var toBaseType = _unitBaseTypes[toUnit];

    if (fromBaseType != toBaseType) {
      debugPrint('❌ Cannot convert different unit types: $fromUnit -> $toUnit');
      return 0.0;
    }

    // Convert: value * fromMultiplier / toMultiplier
    double result = (value * fromMultiplier) / toMultiplier;

    debugPrint('✅ Unit conversion: $value $fromUnit = $result $toUnit');
    return result;
  }

  /// FIXED: Enhanced calculate cost with unit conversion support
  static CalculationResult calculateSmartCost({
    required double totalPrice,
    required double packageQuantity,
    required String packageUnit,
    required double usageAmount,
    required String usageUnit,
  }) {
    // Handle percentage calculation
    if (usageUnit == '%' || usageUnit == AppConstants.defaultUsageUnit) {
      return calculatePercentageCost(
        totalPrice: totalPrice,
        packageQuantity: packageQuantity,
        percentageUsed: usageAmount,
      );
    }

    // Handle unit conversion calculation
    return calculateConvertedUnitCost(
      totalPrice: totalPrice,
      packageQuantity: packageQuantity,
      packageUnit: packageUnit,
      unitsUsed: usageAmount,
      usageUnit: usageUnit,
    );
  }

  /// Calculate cost berdasarkan percentage dengan validation
  static CalculationResult calculatePercentageCost({
    required double totalPrice,
    required double packageQuantity,
    required double percentageUsed,
  }) {
    // Validate inputs using integrated validators
    final priceValidation = InputValidator.validatePrice(totalPrice.toString());
    if (priceValidation != null) {
      return CalculationResult.error('Total harga: $priceValidation');
    }

    final quantityValidation =
        InputValidator.validateQuantity(packageQuantity.toString());
    if (quantityValidation != null) {
      return CalculationResult.error('Jumlah package: $quantityValidation');
    }

    final percentageValidation =
        InputValidator.validatePercentage(percentageUsed.toString());
    if (percentageValidation != null) {
      return CalculationResult.error('Persentase: $percentageValidation');
    }

    // Check against constants
    if (totalPrice > AppConstants.maxPrice) {
      return CalculationResult.error(AppConstants.errorMaxPrice);
    }

    if (percentageUsed > AppConstants.maxPercentage) {
      return CalculationResult.error(AppConstants.errorInvalidPercentage);
    }

    // Calculate cost
    double cost = totalPrice * (percentageUsed / 100);

    // Validate result
    if (cost > AppConstants.maxPrice) {
      return CalculationResult.error('Hasil perhitungan terlalu besar');
    }

    return CalculationResult.success(
      cost: cost,
      calculation:
          'Rp ${AppFormatters.formatRupiah(totalPrice)} × ${formatPercentage(percentageUsed)} = ${AppFormatters.formatRupiah(cost)}',
      unitUsed: '${formatPercentage(percentageUsed)} dari total',
    );
  }

  /// Calculate cost berdasarkan unit exact dengan validation yang lebih fleksibel
  static CalculationResult calculateUnitCost({
    required double totalPrice,
    required double packageQuantity,
    required double unitsUsed,
  }) {
    // Validate inputs using integrated validators
    final priceValidation = InputValidator.validatePrice(totalPrice.toString());
    if (priceValidation != null) {
      return CalculationResult.error('Total harga: $priceValidation');
    }

    final packageQuantityValidation =
        InputValidator.validateQuantity(packageQuantity.toString());
    if (packageQuantityValidation != null) {
      return CalculationResult.error(
          'Jumlah dalam package: $packageQuantityValidation');
    }

    final unitsUsedValidation =
        InputValidator.validateQuantity(unitsUsed.toString());
    if (unitsUsedValidation != null) {
      return CalculationResult.error(
          'Jumlah yang dipakai: $unitsUsedValidation');
    }

    // Check against constants
    if (totalPrice > AppConstants.maxPrice) {
      return CalculationResult.error(AppConstants.errorMaxPrice);
    }

    if (packageQuantity > AppConstants.maxQuantity ||
        unitsUsed > AppConstants.maxQuantity) {
      return CalculationResult.error('Jumlah melebihi batas maksimal');
    }

    // Allow flexible unit conversion scenarios
    if (unitsUsed > packageQuantity * 50) {
      // Allow up to 50x for unit conversion scenarios
      return CalculationResult.error(
          'Jumlah yang dipakai terlalu besar. Periksa satuan dan jumlah kembali.');
    }

    // Calculate unit price and total cost
    double pricePerUnit = totalPrice / packageQuantity;
    double totalCost = pricePerUnit * unitsUsed;

    // Validate result is reasonable
    if (totalCost > AppConstants.maxPrice) {
      return CalculationResult.error('Hasil perhitungan terlalu besar');
    }

    return CalculationResult.success(
      cost: totalCost,
      calculation:
          '${AppFormatters.formatRupiah(pricePerUnit)} per unit × $unitsUsed unit = ${AppFormatters.formatRupiah(totalCost)}',
      unitUsed: '$unitsUsed unit (dari $packageQuantity unit dibeli)',
    );
  }

  /// Get usage suggestion berdasarkan jenis UMKM dengan enhanced validation
  static UsageSuggestion getUsageSuggestion(String businessType) {
    // Validate business type input
    final nameValidation = InputValidator.validateName(businessType);
    if (nameValidation != null) {
      // Return default suggestion if invalid input
      return _getDefaultSuggestion();
    }

    switch (businessType.toLowerCase().trim()) {
      case 'fnb':
      case 'makanan':
      case 'food':
      case 'kuliner':
        return UsageSuggestion(
          businessType: 'FnB/Makanan',
          primaryUnit: 'Gram (gr)', // Lebih praktis untuk masakan
          secondaryUnits: ['Kilogram (kg)', 'Mililiter (ml)', 'pcs (pieces)'],
          examples: [
            'Beras: 200 gram per porsi',
            'Santan: 100 mililiter per porsi',
            'Telur: 1 pcs per porsi',
            'Daging: 150 gram per porsi',
          ],
          description:
              'Gunakan gram untuk bahan makanan padat, mililiter untuk cairan',
          advantages: [
            'Presisi tinggi untuk resep',
            'Mudah diukur di dapur',
            'Cocok untuk kontrol porsi',
          ],
        );

      case 'konveksi':
      case 'fashion':
      case 'garment':
      case 'tekstil':
        return UsageSuggestion(
          businessType: 'Konveksi/Fashion',
          primaryUnit: 'Centimeter (cm)',
          secondaryUnits: [
            'Meter (m)',
            AppConstants.defaultUsageUnit,
            'pcs (pieces)'
          ],
          examples: [
            'Kain: 80 centimeter per kaos',
            'Benang: 5% dari 1 gulung',
            'Kancing: 5 pcs per baju',
            'Resleting: 60 centimeter per celana',
          ],
          description: 'Gunakan centimeter untuk kain, pcs untuk aksesoris',
          advantages: [
            'Presisi untuk pemotongan kain',
            'Mudah menghitung kebutuhan material',
            'Standard industri garment Indonesia',
          ],
        );

      default:
        return _getDefaultSuggestion();
    }
  }

  /// Default suggestion menggunakan constants
  static UsageSuggestion _getDefaultSuggestion() {
    return UsageSuggestion(
      businessType: 'Umum',
      primaryUnit: AppConstants.defaultUsageUnit, // %
      secondaryUnits: ['Kilogram (kg)', 'Gram (gr)', 'pcs (pieces)'],
      examples: [
        'Bahan A: 5% dari pembelian',
        'Bahan B: 200 gram per produk',
        'Komponen: 2 pcs per unit',
        'Material: 1 kilogram per batch',
      ],
      description:
          'Persentase cocok untuk semua jenis usaha, mudah dipahami dan dihitung',
      advantages: [
        'Universal untuk semua bisnis',
        'Mudah dipelajari',
        'Fleksibel untuk berbagai kondisi',
      ],
    );
  }

  /// Format percentage dengan validation menggunakan integrated formatter
  static String formatPercentage(double percentage) {
    return AppFormatters.formatPercentage(percentage);
  }

  /// Comprehensive percentage validation menggunakan integrated validator dan constants
  static ValidationResult validatePercentage(double percentage) {
    // Use integrated validator first
    final basicValidation =
        InputValidator.validatePercentage(percentage.toString());
    if (basicValidation != null) {
      return ValidationResult(
        isValid: false,
        message: basicValidation,
        severity: ValidationSeverity.error,
      );
    }

    // Additional business logic validation using constants
    if (percentage < AppConstants.minPercentage) {
      return ValidationResult(
        isValid: false,
        message: 'Persentase harus minimal ${AppConstants.minPercentage}%',
        severity: ValidationSeverity.error,
      );
    }

    if (percentage > AppConstants.maxPercentage) {
      return ValidationResult(
        isValid: false,
        message: AppConstants.errorInvalidPercentage,
        severity: ValidationSeverity.error,
      );
    }

    // Warning for high percentages
    if (percentage > 50) {
      return ValidationResult(
        isValid: true,
        message:
            'Persentase tinggi (${formatPercentage(percentage)}) - pastikan sudah benar',
        severity: ValidationSeverity.warning,
        suggestion:
            'Cek kembali perhitungan. Apakah benar menggunakan ${formatPercentage(percentage)} dari total bahan?',
      );
    }

    // Warning for very low percentages
    if (percentage < 1) {
      return ValidationResult(
        isValid: true,
        message: 'Persentase sangat kecil (${formatPercentage(percentage)})',
        severity: ValidationSeverity.info,
        suggestion:
            'Pertimbangkan menggunakan unit yang lebih spesifik (gram, ml) untuk akurasi lebih baik.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: 'Persentase valid',
      severity: ValidationSeverity.success,
    );
  }

  /// Calculate harga per unit untuk reference dengan validation
  static CalculationResult calculateUnitPrice({
    required double totalPrice,
    required double packageQuantity,
  }) {
    // Validate using integrated validators
    final priceValidation = InputValidator.validatePrice(totalPrice.toString());
    if (priceValidation != null) {
      return CalculationResult.error('Total harga: $priceValidation');
    }

    final quantityValidation =
        InputValidator.validateQuantity(packageQuantity.toString());
    if (quantityValidation != null) {
      return CalculationResult.error('Jumlah package: $quantityValidation');
    }

    // Check against constants
    if (totalPrice > AppConstants.maxPrice) {
      return CalculationResult.error(AppConstants.errorMaxPrice);
    }

    double unitPrice = totalPrice / packageQuantity;

    // Validate result
    if (unitPrice > AppConstants.maxPrice) {
      return CalculationResult.error('Harga per unit terlalu besar');
    }

    return CalculationResult.success(
      cost: unitPrice,
      calculation:
          '${AppFormatters.formatRupiah(totalPrice)} ÷ $packageQuantity = ${AppFormatters.formatRupiah(unitPrice)} per unit',
      unitUsed: '1 unit dari $packageQuantity unit',
    );
  }

  /// Format rupiah menggunakan integrated formatter
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// Get common business types dengan validation
  static List<BusinessTypeInfo> getBusinessTypes() {
    return [
      BusinessTypeInfo(
        id: 'fnb',
        name: 'FnB/Makanan',
        description: 'Makanan, minuman, kuliner',
        recommendedUnit: 'Gram (gr)',
        examples: ['Warung', 'Restoran', 'Catering', 'Bakery'],
      ),
      BusinessTypeInfo(
        id: 'konveksi',
        name: 'Konveksi/Fashion',
        description: 'Garment, tekstil, fashion',
        recommendedUnit: 'Centimeter (cm)',
        examples: ['Konveksi', 'Tailor', 'Fashion', 'Bordir'],
      ),
      BusinessTypeInfo(
        id: 'retail',
        name: 'Retail/Toko',
        description: 'Toko, grosir, eceran',
        recommendedUnit: 'pcs (pieces)',
        examples: ['Mini Market', 'Grosir', 'Online Shop', 'Toko Kelontong'],
      ),
      BusinessTypeInfo(
        id: 'lainnya',
        name: 'Lainnya',
        description: 'Jenis usaha lainnya',
        recommendedUnit: AppConstants.defaultUsageUnit,
        examples: ['Custom', 'Campuran', 'Unik'],
      ),
    ];
  }

  /// Smart unit suggestion berdasarkan nama bahan
  static String suggestUnitForIngredient(String ingredientName) {
    final name = ingredientName.toLowerCase().trim();

    // Validate input first
    final nameValidation = InputValidator.validateName(ingredientName);
    if (nameValidation != null) {
      return AppConstants.defaultUsageUnit;
    }

    // Liquid materials - use mililiter
    if (name.contains('minyak') ||
        name.contains('air') ||
        name.contains('susu') ||
        name.contains('kecap') ||
        name.contains('saos') ||
        name.contains('sirup') ||
        name.contains('santan')) {
      return 'Mililiter (ml)';
    }

    // Powder/grain materials - use gram
    if (name.contains('tepung') ||
        name.contains('gula') ||
        name.contains('garam') ||
        name.contains('bumbu') ||
        name.contains('rempah') ||
        name.contains('beras')) {
      return 'Gram (gr)';
    }

    // Heavy materials - use kilogram
    if (name.contains('daging') ||
        name.contains('ayam') ||
        name.contains('ikan') ||
        name.contains('sayur')) {
      return 'Kilogram (kg)';
    }

    // Fabric materials - use centimeter
    if (name.contains('kain') ||
        name.contains('bahan') ||
        name.contains('katun') ||
        name.contains('polyester') ||
        name.contains('sutra') ||
        name.contains('denim')) {
      return 'Centimeter (cm)';
    }

    // Individual items - use pieces
    if (name.contains('telur') ||
        name.contains('bawang') ||
        name.contains('kancing') ||
        name.contains('resleting') ||
        name.contains('pensil') ||
        name.contains('pulpen')) {
      return 'pcs (pieces)';
    }

    // Default to percentage for flexibility
    return AppConstants.defaultUsageUnit; // %
  }

  /// Calculate efficiency ratio untuk analisis
  static EfficiencyAnalysis analyzeUsageEfficiency({
    required double percentageUsed,
    required String businessType,
    required String ingredientType,
  }) {
    // Validate inputs
    final percentageValidation = validatePercentage(percentageUsed);
    if (!percentageValidation.isValid) {
      return EfficiencyAnalysis.error(percentageValidation.message);
    }

    String efficiency;
    String recommendation;
    EfficiencyLevel level;

    // Business-specific efficiency analysis
    if (businessType.toLowerCase().contains('fnb')) {
      if (percentageUsed <= 2) {
        efficiency = 'Sangat Efisien';
        level = EfficiencyLevel.excellent;
        recommendation = 'Penggunaan bahan sangat optimal untuk bisnis FnB';
      } else if (percentageUsed <= 5) {
        efficiency = 'Efisien';
        level = EfficiencyLevel.good;
        recommendation = 'Penggunaan bahan masih dalam batas wajar';
      } else if (percentageUsed <= 10) {
        efficiency = 'Cukup Efisien';
        level = EfficiencyLevel.fair;
        recommendation = 'Pertimbangkan optimasi porsi atau resep';
      } else {
        efficiency = 'Kurang Efisien';
        level = EfficiencyLevel.poor;
        recommendation = 'Perlu evaluasi ulang penggunaan bahan atau supplier';
      }
    } else {
      // General efficiency analysis
      if (percentageUsed <= 5) {
        efficiency = 'Sangat Efisien';
        level = EfficiencyLevel.excellent;
        recommendation = 'Penggunaan bahan sangat optimal';
      } else if (percentageUsed <= 15) {
        efficiency = 'Efisien';
        level = EfficiencyLevel.good;
        recommendation = 'Penggunaan bahan dalam batas normal';
      } else if (percentageUsed <= 25) {
        efficiency = 'Cukup Efisien';
        level = EfficiencyLevel.fair;
        recommendation = 'Masih dapat dioptimalkan';
      } else {
        efficiency = 'Kurang Efisien';
        level = EfficiencyLevel.poor;
        recommendation = 'Perlu evaluasi sistem produksi';
      }
    }

    return EfficiencyAnalysis(
      efficiency: efficiency,
      level: level,
      recommendation: recommendation,
      percentageUsed: percentageUsed,
      isOptimal:
          level == EfficiencyLevel.excellent || level == EfficiencyLevel.good,
    );
  }

  /// Helper function for debug printing (replaces print statements)
  static void debugPrint(String message) {
    // In production, you could use a proper logging framework
    // For now, this is a placeholder that could be replaced with:
    // - logger.debug(message)
    // - Developer.log(message)
    // - or simply removed in production builds
    assert(() {
      print(message); // Only prints in debug mode
      return true;
    }());
  }

  // Tambahkan method ini ke UniversalUnitService untuk testing
  // ... existing code ...

  /// DEBUG: Test unit conversion untuk troubleshooting
  static void debugUnitConversion() {
    print("=== TESTING UNIT CONVERSION ===");

    // Test case 1: Kilogram to Gram
    print("\n1. Testing Kilogram to Gram:");
    print("Available units: ${_unitBaseTypes.keys.toList()}");

    bool canConvert1 = _areUnitsConvertible('Kilogram (kg)', 'Gram (gr)');
    print("Can convert Kilogram (kg) → Gram (gr): $canConvert1");

    if (canConvert1) {
      double result1 = _convertUnits(
        value: 5.0,
        fromUnit: 'Kilogram (kg)',
        toUnit: 'Gram (gr)',
      );
      print("5 Kilogram (kg) = $result1 Gram (gr)");
      print("Expected: 5000, Got: $result1, Match: ${result1 == 5000}");
    }

    // Test case 2: Liter to Mililiter
    print("\n2. Testing Liter to Mililiter:");
    bool canConvert2 = _areUnitsConvertible('Liter (L)', 'Mililiter (ml)');
    print("Can convert Liter (L) → Mililiter (ml): $canConvert2");

    if (canConvert2) {
      double result2 = _convertUnits(
        value: 1.0,
        fromUnit: 'Liter (L)',
        toUnit: 'Mililiter (ml)',
      );
      print("1 Liter (L) = $result2 Mililiter (ml)");
      print("Expected: 1000, Got: $result2, Match: ${result2 == 1000}");
    }

    // Test case 3: Full calculation
    print("\n3. Testing Full Calculation:");
    var result = calculateSmartCost(
      totalPrice: 350000.0,
      packageQuantity: 5.0,
      packageUnit: 'Kilogram (kg)',
      usageAmount: 25.0,
      usageUnit: 'Gram (gr)',
    );

    print("Calculation success: ${result.isSuccess}");
    if (result.isSuccess) {
      print("Cost: ${result.cost}");
      print("Expected: ~1750, Got: ${result.cost}");
    } else {
      print("Error: ${result.errorMessage}");
    }

    print("\n=== END TEST ===");
  }

  /// DEBUG: Print semua unit yang tersedia
  static void printAvailableUnits() {
    print("=== AVAILABLE UNITS ===");
    print("Package Units: ${getPackageUnits()}");
    print("Usage Units: ${getUsageUnits()}");
    print("Base Types: $_unitBaseTypes");
    print("Multipliers: $_unitMultipliers");
  }
}

// Enhanced data classes with validation

class UsageSuggestion {
  final String businessType;
  final String primaryUnit;
  final List<String> secondaryUnits;
  final List<String> examples;
  final String description;
  final List<String> advantages;

  UsageSuggestion({
    required this.businessType,
    required this.primaryUnit,
    required this.secondaryUnits,
    required this.examples,
    required this.description,
    required this.advantages,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessType': businessType,
      'primaryUnit': primaryUnit,
      'secondaryUnits': secondaryUnits,
      'examples': examples,
      'description': description,
      'advantages': advantages,
    };
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  final ValidationSeverity severity;
  final String? suggestion;

  ValidationResult({
    required this.isValid,
    required this.message,
    required this.severity,
    this.suggestion,
  });
}

enum ValidationSeverity {
  success,
  info,
  warning,
  error,
}

class CalculationResult {
  final bool isSuccess;
  final double cost;
  final String? errorMessage;
  final String? calculation;
  final String? unitUsed;

  CalculationResult._({
    required this.isSuccess,
    required this.cost,
    this.errorMessage,
    this.calculation,
    this.unitUsed,
  });

  factory CalculationResult.success({
    required double cost,
    required String calculation,
    required String unitUsed,
  }) {
    return CalculationResult._(
      isSuccess: true,
      cost: cost,
      calculation: calculation,
      unitUsed: unitUsed,
    );
  }

  factory CalculationResult.error(String message) {
    return CalculationResult._(
      isSuccess: false,
      cost: 0.0,
      errorMessage: message,
    );
  }
}

class BusinessTypeInfo {
  final String id;
  final String name;
  final String description;
  final String recommendedUnit;
  final List<String> examples;

  BusinessTypeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.recommendedUnit,
    required this.examples,
  });
}

class EfficiencyAnalysis {
  final bool isSuccess;
  final String efficiency;
  final EfficiencyLevel level;
  final String recommendation;
  final double percentageUsed;
  final bool isOptimal;
  final String? errorMessage;

  EfficiencyAnalysis._({
    required this.isSuccess,
    required this.efficiency,
    required this.level,
    required this.recommendation,
    required this.percentageUsed,
    required this.isOptimal,
    this.errorMessage,
  });

  factory EfficiencyAnalysis({
    required String efficiency,
    required EfficiencyLevel level,
    required String recommendation,
    required double percentageUsed,
    required bool isOptimal,
  }) {
    return EfficiencyAnalysis._(
      isSuccess: true,
      efficiency: efficiency,
      level: level,
      recommendation: recommendation,
      percentageUsed: percentageUsed,
      isOptimal: isOptimal,
    );
  }

  factory EfficiencyAnalysis.error(String message) {
    return EfficiencyAnalysis._(
      isSuccess: false,
      efficiency: 'Error',
      level: EfficiencyLevel.error,
      recommendation: 'Perbaiki input data terlebih dahulu',
      percentageUsed: 0.0,
      isOptimal: false,
      errorMessage: message,
    );
  }
}

enum EfficiencyLevel {
  excellent,
  good,
  fair,
  poor,
  error,
}
