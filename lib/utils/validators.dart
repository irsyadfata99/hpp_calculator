// lib/utils/validators.dart
import 'constants.dart';

class InputValidator {
  /// Validate name input (for bahan, menu, karyawan, etc.)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.errorEmptyName;
    }

    if (value.trim().length > AppConstants.maxTextLength) {
      return 'Nama terlalu panjang (maksimal ${AppConstants.maxTextLength} karakter)';
    }

    // Check for invalid characters - simple check
    if (value.contains('<') || value.contains('>') || value.contains('"')) {
      return 'Nama mengandung karakter yang tidak diizinkan';
    }

    return null;
  }

  /// Validate price input
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga tidak boleh kosong';
    }

    // Remove currency formatting if present
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

  /// Validate salary input (for employee salary validation)
  static String? validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gaji tidak boleh kosong';
    }

    // Remove currency formatting if present
    String cleanValue = value.replaceAll(RegExp(r'[Rp\.,\s]'), '');

    double? salary = double.tryParse(cleanValue);
    if (salary == null) {
      return 'Gaji harus berupa angka yang valid';
    }

    if (salary < 0) {
      return 'Gaji tidak boleh negatif';
    }

    if (salary > AppConstants.maxPrice) {
      return 'Gaji terlalu besar';
    }

    return null;
  }

  /// Validate quantity input
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
      return 'Jumlah terlalu besar (maksimal ${AppConstants.maxQuantity})';
    }

    return null;
  }

  /// Validate percentage input
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

  /// Clean numeric input (remove formatting)
  static String cleanNumericInput(String input) {
    return input.replaceAll(RegExp(r'[^\d\.]'), '');
  }
}
