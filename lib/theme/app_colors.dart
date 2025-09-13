// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (existing dari desain)
  static const Color primary = Color(0xFF476EAE);
  static const Color secondary = Color(0xFF48B3AF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Background & Surface
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Category Colors (untuk different widgets)
  static const Color hppCategory =
      Color(0xFF4CAF50); // Green for variable costs
  static const Color operationalCategory =
      Color(0xFFFF9800); // Orange for operational
  static const Color menuCategory = Color(0xFF9C27B0); // Purple for menu
  static const Color fixedCostCategory =
      Color(0xFF48B3AF); // Teal for fixed costs

  // State Colors
  static const Color disabled = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFECFDFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light/Dark variants
  static Color primaryLight = primary.withOpacity(0.1);
  static Color primaryDark = const Color(0xFF2E4B7A);
  static Color secondaryLight = secondary.withOpacity(0.1);
  static Color secondaryDark = const Color(0xFF2E7B78);

  // Helper methods
  static Color withAlpha(Color color, double alpha) {
    return color.withOpacity(alpha);
  }

  static Color lighten(Color color, [double factor = 0.1]) {
    assert(factor >= 0 && factor <= 1);
    return Color.lerp(color, Colors.white, factor) ?? color;
  }

  static Color darken(Color color, [double factor = 0.1]) {
    assert(factor >= 0 && factor <= 1);
    return Color.lerp(color, Colors.black, factor) ?? color;
  }
}

// Color scheme extensions for specific widgets
class HPPColors {
  static const Color variableCost = AppColors.success;
  static const Color fixedCost = AppColors.secondary;
  static const Color result = AppColors.primary;

  static Color variableCostLight = variableCost.withOpacity(0.1);
  static Color fixedCostLight = fixedCost.withOpacity(0.1);
  static Color resultLight = result.withOpacity(0.1);
}

class OperationalColors {
  static const Color karyawan = AppColors.warning;
  static const Color cost = AppColors.secondary;
  static const Color result = AppColors.primary;

  static Color karyawanLight = karyawan.withOpacity(0.1);
  static Color costLight = cost.withOpacity(0.1);
  static Color resultLight = result.withOpacity(0.1);
}

class MenuColors {
  static const Color input = AppColors.info;
  static const Color ingredient = AppColors.success;
  static const Color composition = AppColors.menuCategory;
  static const Color result = AppColors.primary;

  static Color inputLight = input.withOpacity(0.1);
  static Color ingredientLight = ingredient.withOpacity(0.1);
  static Color compositionLight = composition.withOpacity(0.1);
  static Color resultLight = result.withOpacity(0.1);
}
