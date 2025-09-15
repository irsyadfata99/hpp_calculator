// lib/services/universal_unit_service.dart - FIXED: Safe Unit Conversion
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class UniversalUnitService {
  // FIXED: Simplified unit mappings without complex conversions
  static final Map<String, String> _unitCategories = {
    // Weight units
    'Kilogram (kg)': 'weight',
    'Gram (gr)': 'weight',
    'Ons': 'weight',

    // Volume units
    'Liter (L)': 'volume',
    'Mililiter (ml)': 'volume',

    // Length units
    'Meter (m)': 'length',
    'Centimeter (cm)': 'length',

    // Piece units
    'pcs (pieces)': 'pieces',
    'unit': 'pieces',
    'Pack': 'pieces',
    'Lusin': 'pieces',
  };

  // FIXED: Simple conversion factors (gram as base for weight, ml for volume)
  static final Map<String, double> _conversionFactors = {
    // Weight to grams
    'Kilogram (kg)': 1000.0,
    'Gram (gr)': 1.0,
    'Ons': 100.0,

    // Volume to ml
    'Liter (L)': 1000.0,
    'Mililiter (ml)': 1.0,

    // Length to cm
    'Meter (m)': 100.0,
    'Centimeter (cm)': 1.0,

    // Pieces (no conversion)
    'pcs (pieces)': 1.0,
    'unit': 1.0,
    'Pack': 1.0,
    'Lusin': 12.0,
  };

  /// Units untuk belanja bahan (HPP Calculator)
  static List<String> getPackageUnits() {
    return [
      'unit',
      'Kilogram (kg)',
      'Liter (L)',
      'pcs (pieces)',
      'Pack',
      'Lusin',
      'Meter (m)',
    ];
  }

  /// Units untuk komposisi menu (Menu Calculator)
  static List<String> getUsageUnits() {
    return [
      AppConstants.defaultUsageUnit, // % (Persentase)
      'Gram (gr)',
      'Mililiter (ml)',
      'Centimeter (cm)',
      'pcs (pieces)',
      'Kilogram (kg)',
      'Ons',
    ];
  }

  /// FIXED: Smart cost calculation with comprehensive safety checks
  static CalculationResult calculateSmartCost({
    required double totalPrice,
    required double packageQuantity,
    required String packageUnit,
    required double usageAmount,
    required String usageUnit,
  }) {
    // FIXED: Division by zero protection
    if (packageQuantity <= 0) {
      return CalculationResult.error('Package quantity must be greater than 0');
    }

    if (usageAmount <= 0) {
      return CalculationResult.error('Usage amount must be greater than 0');
    }

    if (totalPrice <= 0) {
      return CalculationResult.error('Total price must be greater than 0');
    }

    try {
      // Handle percentage calculation
      if (usageUnit == '%' || usageUnit == AppConstants.defaultUsageUnit) {
        return _calculatePercentageCost(
            totalPrice, packageQuantity, usageAmount);
      }

      // Handle same unit calculation (no conversion needed)
      if (packageUnit == usageUnit) {
        return _calculateDirectCost(
            totalPrice, packageQuantity, usageAmount, usageUnit);
      }

      // Handle unit conversion calculation
      return _calculateConvertedCost(
          totalPrice, packageQuantity, packageUnit, usageAmount, usageUnit);
    } catch (e) {
      return CalculationResult.error('Calculation error: ${e.toString()}');
    }
  }

  /// FIXED: Safe percentage calculation
  static CalculationResult _calculatePercentageCost(
      double totalPrice, double packageQuantity, double percentage) {
    // Validate percentage range
    if (percentage < AppConstants.minPercentage ||
        percentage > AppConstants.maxPercentage) {
      return CalculationResult.error(
          'Percentage must be between ${AppConstants.minPercentage}% and ${AppConstants.maxPercentage}%');
    }

    double cost = totalPrice * (percentage / 100.0);

    // Validate result
    if (cost > AppConstants.maxPrice) {
      return CalculationResult.error('Calculated cost is too high');
    }

    return CalculationResult.success(
      cost: cost,
      calculation:
          '${AppFormatters.formatRupiah(totalPrice)} × ${AppFormatters.formatPercentage(percentage)} = ${AppFormatters.formatRupiah(cost)}',
      unitUsed:
          '${AppFormatters.formatPercentage(percentage)} of total purchase',
    );
  }

  /// FIXED: Safe direct cost calculation (same units)
  static CalculationResult _calculateDirectCost(double totalPrice,
      double packageQuantity, double usageAmount, String unit) {
    // FIXED: Division by zero protection
    if (packageQuantity <= 0) {
      return CalculationResult.error('Package quantity cannot be zero');
    }

    double unitPrice = totalPrice / packageQuantity;
    double totalCost = unitPrice * usageAmount;

    // Validate result
    if (totalCost > AppConstants.maxPrice) {
      return CalculationResult.error('Calculated cost is too high');
    }

    return CalculationResult.success(
      cost: totalCost,
      calculation:
          '${AppFormatters.formatRupiah(unitPrice)} per $unit × $usageAmount $unit = ${AppFormatters.formatRupiah(totalCost)}',
      unitUsed: '$usageAmount $unit from $packageQuantity $unit purchased',
    );
  }

  /// FIXED: Safe unit conversion calculation
  static CalculationResult _calculateConvertedCost(
      double totalPrice,
      double packageQuantity,
      String packageUnit,
      double usageAmount,
      String usageUnit) {
    // Check if units can be converted
    if (!_areUnitsConvertible(packageUnit, usageUnit)) {
      return CalculationResult.error(
          'Cannot convert from $packageUnit to $usageUnit - different unit types');
    }

    try {
      // Get conversion factors
      double? packageFactor = _conversionFactors[packageUnit];
      double? usageFactor = _conversionFactors[usageUnit];

      if (packageFactor == null || usageFactor == null) {
        return CalculationResult.error(
            'Conversion factors not found for units');
      }

      // FIXED: Safe conversion with division by zero protection
      if (usageFactor <= 0) {
        return CalculationResult.error('Invalid usage unit conversion factor');
      }

      // Convert package quantity to usage unit
      double convertedPackageQuantity =
          (packageQuantity * packageFactor) / usageFactor;

      // FIXED: Division by zero protection after conversion
      if (convertedPackageQuantity <= 0) {
        return CalculationResult.error(
            'Unit conversion resulted in invalid quantity');
      }

      double unitPrice = totalPrice / convertedPackageQuantity;
      double totalCost = unitPrice * usageAmount;

      // Validate result
      if (totalCost > AppConstants.maxPrice) {
        return CalculationResult.error('Calculated cost is too high');
      }

      return CalculationResult.success(
        cost: totalCost,
        calculation:
            '${AppFormatters.formatRupiah(totalPrice)} ÷ ${convertedPackageQuantity.toStringAsFixed(2)} $usageUnit × $usageAmount $usageUnit = ${AppFormatters.formatRupiah(totalCost)}',
        unitUsed:
            '$usageAmount $usageUnit (converted from $packageQuantity $packageUnit)',
      );
    } catch (e) {
      return CalculationResult.error('Unit conversion failed: ${e.toString()}');
    }
  }

  /// FIXED: Simple unit compatibility check
  static bool _areUnitsConvertible(String unit1, String unit2) {
    if (unit1 == unit2) return true;

    String? category1 = _unitCategories[unit1];
    String? category2 = _unitCategories[unit2];

    if (category1 == null || category2 == null) return false;

    return category1 == category2;
  }

  /// FIXED: Safe unit price calculation with division by zero protection
  static CalculationResult calculateUnitPrice({
    required double totalPrice,
    required double packageQuantity,
  }) {
    // FIXED: Input validation
    if (totalPrice <= 0) {
      return CalculationResult.error('Total price must be greater than 0');
    }

    if (packageQuantity <= 0) {
      return CalculationResult.error('Package quantity must be greater than 0');
    }

    if (totalPrice > AppConstants.maxPrice) {
      return CalculationResult.error('Total price is too high');
    }

    try {
      double unitPrice = totalPrice / packageQuantity;

      // Validate result
      if (unitPrice > AppConstants.maxPrice) {
        return CalculationResult.error('Unit price is too high');
      }

      if (!unitPrice.isFinite) {
        return CalculationResult.error('Invalid unit price calculation');
      }

      return CalculationResult.success(
        cost: unitPrice,
        calculation:
            '${AppFormatters.formatRupiah(totalPrice)} ÷ $packageQuantity = ${AppFormatters.formatRupiah(unitPrice)} per unit',
        unitUsed: '1 unit from $packageQuantity units',
      );
    } catch (e) {
      return CalculationResult.error(
          'Unit price calculation failed: ${e.toString()}');
    }
  }

  /// Format rupiah menggunakan integrated formatter
  static String formatRupiah(double amount) {
    return AppFormatters.formatRupiah(amount);
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return AppFormatters.formatPercentage(percentage);
  }

  /// Smart unit suggestion berdasarkan nama bahan
  static String suggestUnitForIngredient(String ingredientName) {
    final name = ingredientName.toLowerCase().trim();

    // Validate input first
    final nameValidation = InputValidator.validateName(ingredientName);
    if (nameValidation != null) {
      return AppConstants.defaultUsageUnit;
    }

    // Liquid materials
    if (name.contains('minyak') ||
        name.contains('air') ||
        name.contains('susu') ||
        name.contains('kecap') ||
        name.contains('saos') ||
        name.contains('santan')) {
      return 'Mililiter (ml)';
    }

    // Powder/grain materials
    if (name.contains('tepung') ||
        name.contains('gula') ||
        name.contains('garam') ||
        name.contains('bumbu') ||
        name.contains('beras')) {
      return 'Gram (gr)';
    }

    // Heavy materials
    if (name.contains('daging') ||
        name.contains('ayam') ||
        name.contains('ikan')) {
      return 'Kilogram (kg)';
    }

    // Fabric materials
    if (name.contains('kain') || name.contains('katun')) {
      return 'Centimeter (cm)';
    }

    // Individual items
    if (name.contains('telur') ||
        name.contains('bawang') ||
        name.contains('kancing')) {
      return 'pcs (pieces)';
    }

    // Default to percentage for flexibility
    return AppConstants.defaultUsageUnit;
  }
}

// FIXED: Simple and safe result classes
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
