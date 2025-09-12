// File: lib/services/universal_unit_service.dart

class UniversalUnitService {
  /// Generic package units untuk semua jenis UMKM
  static List<String> getPackageUnits() {
    return [
      'unit', // Universal unit
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
      '%', // Percentage - UNIVERSAL SOLUTION
      'unit', // Piece/unit
      'gram', // Weight
      'ml', // Volume
      'meter', // Length
      'lembar', // Sheet
      'potong', // Cut/piece
      'porsi', // Portion
    ];
  }

  /// Calculate cost berdasarkan percentage
  static double calculatePercentageCost({
    required double totalPrice,
    required double packageQuantity,
    required double percentageUsed,
  }) {
    if (packageQuantity <= 0 || percentageUsed <= 0) return 0.0;

    // Total value dari semua package
    double totalValue = totalPrice;

    // Hitung cost berdasarkan percentage
    return totalValue * (percentageUsed / 100);
  }

  /// Calculate cost berdasarkan unit exact
  static double calculateUnitCost({
    required double totalPrice,
    required double packageQuantity,
    required double unitsUsed,
  }) {
    if (packageQuantity <= 0 || unitsUsed <= 0) return 0.0;

    // Harga per unit
    double pricePerUnit = totalPrice / packageQuantity;

    // Total cost untuk units yang dipakai
    return pricePerUnit * unitsUsed;
  }

  /// Get usage suggestion berdasarkan jenis UMKM
  static UsageSuggestion getUsageSuggestion(String businessType) {
    switch (businessType.toLowerCase()) {
      case 'fnb':
      case 'makanan':
      case 'food':
        return UsageSuggestion(
          primaryUnit: '%',
          examples: [
            'Selai: 5% dari 1 toples',
            'Mentega: 3% dari 1 bungkus',
            'Bumbu: 2% dari 1 pack',
          ],
          description: 'Gunakan persentase untuk bahan makanan',
        );

      case 'konveksi':
      case 'fashion':
      case 'garment':
        return UsageSuggestion(
          primaryUnit: 'meter',
          examples: [
            'Kain: 0.8 meter dari 1 roll',
            'Benang: 10% dari 1 gulung',
            'Kancing: 5 unit dari 1 pack',
          ],
          description: 'Gunakan meter untuk kain, % untuk aksesoris',
        );

      case 'atk':
      case 'stationery':
        return UsageSuggestion(
          primaryUnit: 'unit',
          examples: [
            'Pensil: 1 unit dari 1 box',
            'Kertas: 10 lembar dari 1 pack',
            'Tinta: 5% dari 1 bottle',
          ],
          description: 'Gunakan unit untuk barang satuan, % untuk cairan',
        );

      case 'service':
      case 'jasa':
        return UsageSuggestion(
          primaryUnit: '%',
          examples: [
            'Oli: 10% dari 1 galon',
            'Suku cadang: 1 unit dari 1 set',
            'Bahan kimia: 5% dari 1 bottle',
          ],
          description: 'Gunakan % untuk bahan habis pakai',
        );

      default:
        return UsageSuggestion(
          primaryUnit: '%',
          examples: [
            'Bahan A: 5% dari pembelian',
            'Bahan B: 10% dari total',
            'Bahan C: 3% dari stock',
          ],
          description: 'Persentase cocok untuk semua jenis usaha',
        );
    }
  }

  /// Format percentage dengan benar
  static String formatPercentage(double percentage) {
    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    } else {
      return '${percentage.toStringAsFixed(1)}%';
    }
  }

  /// Validate percentage input
  static ValidationResult validatePercentage(double percentage) {
    if (percentage <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Persentase harus lebih dari 0%',
      );
    }

    if (percentage > 100) {
      return ValidationResult(
        isValid: false,
        message: 'Persentase tidak boleh lebih dari 100%',
      );
    }

    if (percentage > 50) {
      return ValidationResult(
        isValid: true,
        message:
            'Persentase tinggi (${formatPercentage(percentage)}) - pastikan sudah benar',
        isWarning: true,
      );
    }

    return ValidationResult(
      isValid: true,
      message: 'Persentase valid',
    );
  }

  /// Calculate harga per unit untuk reference
  static double calculateUnitPrice({
    required double totalPrice,
    required double packageQuantity,
  }) {
    if (packageQuantity <= 0) return 0.0;
    return totalPrice / packageQuantity;
  }

  /// Format rupiah
  static String formatRupiah(double amount) {
    if (amount.isNaN || amount.isInfinite) {
      return 'Rp 0';
    }

    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Get common business types untuk reference
  static List<String> getBusinessTypes() {
    return [
      'FnB/Makanan',
      'Konveksi/Fashion',
      'ATK/Stationery',
      'Service/Jasa',
      'Retail/Toko',
      'Lainnya',
    ];
  }
}

class UsageSuggestion {
  final String primaryUnit;
  final List<String> examples;
  final String description;

  UsageSuggestion({
    required this.primaryUnit,
    required this.examples,
    required this.description,
  });
}

class ValidationResult {
  final bool isValid;
  final String message;
  final bool isWarning;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.isWarning = false,
  });
}
