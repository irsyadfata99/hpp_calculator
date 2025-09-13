// File: lib/services/universal_unit_service.dart - Integrated with Constants & Validators
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class UniversalUnitService {
  /// Generic package units untuk semua jenis UMKM
  static List<String> getPackageUnits() {
    return [
      AppConstants.defaultUnit, // Using constant for default unit
      'pack', // Package/packaging
      'box', // Box/carton
      'bottle', // Bottle/container
      'roll', // Roll (fabric, paper, etc)
      'lembar', // Sheet/piece
      'kg', // Weight
      'gram', // Weight small
      'liter', // Volume
      'ml', // Volume small
      'meter', // Length
      'yard', // Length (fabric)
      'set', // Set/collection
    ];
  }

  /// Generic usage units untuk komposisi
  static List<String> getUsageUnits() {
    return [
      AppConstants
          .defaultUsageUnit, // Using constant for default usage unit (%)
      AppConstants.defaultUnit, // Piece/unit
      'gram', // Weight
      'ml', // Volume
      'meter', // Length
      'lembar', // Sheet
      'potong', // Cut/piece
      'porsi', // Portion
    ];
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

  /// Calculate cost berdasarkan unit exact dengan validation
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

    // Check logical constraints
    if (unitsUsed > packageQuantity) {
      return CalculationResult.error(
          'Jumlah yang dipakai tidak boleh lebih besar dari jumlah dalam package');
    }

    // Calculate unit price and total cost
    double pricePerUnit = totalPrice / packageQuantity;
    double totalCost = pricePerUnit * unitsUsed;

    // Validate result
    if (totalCost > AppConstants.maxPrice) {
      return CalculationResult.error('Hasil perhitungan terlalu besar');
    }

    return CalculationResult.success(
      cost: totalCost,
      calculation:
          '${AppFormatters.formatRupiah(pricePerUnit)} per unit × $unitsUsed unit = ${AppFormatters.formatRupiah(totalCost)}',
      unitUsed: '$unitsUsed unit dari $packageQuantity unit',
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
          primaryUnit: AppConstants.defaultUsageUnit, // %
          secondaryUnits: ['gram', 'ml', 'unit'],
          examples: [
            'Selai: 5% dari 1 toples (${AppConstants.defaultUsageUnit})',
            'Mentega: 3% dari 1 bungkus (${AppConstants.defaultUsageUnit})',
            'Bumbu: 2% dari 1 pack (${AppConstants.defaultUsageUnit})',
            'Telur: 2 unit dari 1 tray (unit)',
          ],
          description:
              'Gunakan persentase untuk bahan makanan cair/bubuk, unit untuk barang satuan',
          advantages: [
            'Mudah menghitung proporsi',
            'Fleksibel untuk berbagai ukuran pembelian',
            'Cocok untuk resep yang bisa di-scale',
          ],
        );

      case 'konveksi':
      case 'fashion':
      case 'garment':
      case 'tekstil':
        return UsageSuggestion(
          businessType: 'Konveksi/Fashion',
          primaryUnit: 'meter',
          secondaryUnits: [AppConstants.defaultUsageUnit, 'unit', 'lembar'],
          examples: [
            'Kain: 0.8 meter dari 1 roll (meter)',
            'Benang: 10% dari 1 gulung (${AppConstants.defaultUsageUnit})',
            'Kancing: 5 unit dari 1 pack (unit)',
            'Furing: 0.5 meter dari 1 roll (meter)',
          ],
          description:
              'Gunakan meter untuk kain, ${AppConstants.defaultUsageUnit} untuk aksesoris kecil, unit untuk barang satuan',
          advantages: [
            'Presisi untuk penggunaan kain',
            'Mudah menghitung kebutuhan material',
            'Standard industri garment',
          ],
        );

      case 'atk':
      case 'stationery':
      case 'alat tulis':
        return UsageSuggestion(
          businessType: 'ATK/Stationery',
          primaryUnit: AppConstants.defaultUnit, // unit
          secondaryUnits: ['lembar', AppConstants.defaultUsageUnit, 'ml'],
          examples: [
            'Pensil: 1 unit dari 1 box (${AppConstants.defaultUnit})',
            'Kertas: 10 lembar dari 1 pack (lembar)',
            'Tinta: 5% dari 1 bottle (${AppConstants.defaultUsageUnit})',
            'Spidol: 1 unit dari 1 set (${AppConstants.defaultUnit})',
          ],
          description:
              'Gunakan unit untuk barang satuan, lembar untuk kertas, ${AppConstants.defaultUsageUnit} untuk cairan',
          advantages: [
            'Mudah menghitung satuan',
            'Cocok untuk inventory barang',
            'Sesuai kebiasaan toko ATK',
          ],
        );

      case 'service':
      case 'jasa':
      case 'bengkel':
      case 'otomotif':
        return UsageSuggestion(
          businessType: 'Service/Jasa',
          primaryUnit: AppConstants.defaultUsageUnit, // %
          secondaryUnits: [AppConstants.defaultUnit, 'liter', 'ml'],
          examples: [
            'Oli: 10% dari 1 galon (${AppConstants.defaultUsageUnit})',
            'Suku cadang: 1 unit dari 1 set (${AppConstants.defaultUnit})',
            'Bahan kimia: 5% dari 1 bottle (${AppConstants.defaultUsageUnit})',
            'Cairan pembersih: 50 ml dari 1 liter (ml)',
          ],
          description:
              'Gunakan ${AppConstants.defaultUsageUnit} untuk bahan habis pakai, unit untuk spare part',
          advantages: [
            'Fleksibel untuk berbagai jenis service',
            'Mudah menghitung konsumsi bahan',
            'Cocok untuk charging customer',
          ],
        );

      case 'retail':
      case 'toko':
      case 'grosir':
        return UsageSuggestion(
          businessType: 'Retail/Toko',
          primaryUnit: AppConstants.defaultUnit, // unit
          secondaryUnits: [AppConstants.defaultUsageUnit, 'pack', 'box'],
          examples: [
            'Produk satuan: 1 unit dari 1 pack (${AppConstants.defaultUnit})',
            'Kemasan besar: 10% dari 1 karton (${AppConstants.defaultUsageUnit})',
            'Sample: 1 unit dari 1 box (${AppConstants.defaultUnit})',
            'Repack: 5 unit dari 1 pack besar (${AppConstants.defaultUnit})',
          ],
          description:
              'Gunakan unit untuk barang satuan, ${AppConstants.defaultUsageUnit} untuk repacking',
          advantages: [
            'Sesuai dengan sistem POS',
            'Mudah tracking inventory',
            'Cocok untuk berbagai jenis produk',
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
      secondaryUnits: [AppConstants.defaultUnit, 'pack', 'box'],
      examples: [
        'Bahan A: 5% dari pembelian (${AppConstants.defaultUsageUnit})',
        'Bahan B: 10% dari total (${AppConstants.defaultUsageUnit})',
        'Bahan C: 3% dari stock (${AppConstants.defaultUsageUnit})',
        'Komponen: 2 unit dari 1 set (${AppConstants.defaultUnit})',
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
        recommendedUnit: AppConstants.defaultUsageUnit,
        examples: ['Warung', 'Restoran', 'Catering', 'Bakery'],
      ),
      BusinessTypeInfo(
        id: 'konveksi',
        name: 'Konveksi/Fashion',
        description: 'Garment, tekstil, fashion',
        recommendedUnit: 'meter',
        examples: ['Konveksi', 'Tailor', 'Fashion', 'Bordir'],
      ),
      BusinessTypeInfo(
        id: 'atk',
        name: 'ATK/Stationery',
        description: 'Alat tulis, perlengkapan kantor',
        recommendedUnit: AppConstants.defaultUnit,
        examples: ['Toko ATK', 'Percetakan', 'Fotocopy', 'Binding'],
      ),
      BusinessTypeInfo(
        id: 'service',
        name: 'Service/Jasa',
        description: 'Bengkel, service, reparasi',
        recommendedUnit: AppConstants.defaultUsageUnit,
        examples: ['Bengkel Motor', 'Service AC', 'Elektronik', 'Komputer'],
      ),
      BusinessTypeInfo(
        id: 'retail',
        name: 'Retail/Toko',
        description: 'Toko, grosir, eceran',
        recommendedUnit: AppConstants.defaultUnit,
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

    // Liquid/powder materials - use percentage
    if (name.contains('minyak') ||
        name.contains('air') ||
        name.contains('susu') ||
        name.contains('kecap') ||
        name.contains('saos') ||
        name.contains('sirup') ||
        name.contains('tepung') ||
        name.contains('gula') ||
        name.contains('garam') ||
        name.contains('bumbu') ||
        name.contains('rempah')) {
      return AppConstants.defaultUsageUnit; // %
    }

    // Fabric materials - use meter
    if (name.contains('kain') ||
        name.contains('bahan') ||
        name.contains('katun') ||
        name.contains('polyester') ||
        name.contains('sutra') ||
        name.contains('denim')) {
      return 'meter';
    }

    // Individual items - use unit
    if (name.contains('telur') ||
        name.contains('bawang') ||
        name.contains('kancing') ||
        name.contains('resleting') ||
        name.contains('pensil') ||
        name.contains('pulpen')) {
      return AppConstants.defaultUnit; // unit
    }

    // Paper materials - use lembar
    if (name.contains('kertas') ||
        name.contains('karton') ||
        name.contains('amplop')) {
      return 'lembar';
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
