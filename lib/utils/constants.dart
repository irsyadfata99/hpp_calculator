// lib/utils/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'HPP Calculator';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Aplikasi sederhana untuk menghitung HPP (Harga Pokok Penjualan) khusus UMKM';

  // Validation Constants
  static const double maxPrice = 999999999.0;
  static const double minPrice = 0.01;
  static const double maxQuantity = 99999.0;
  static const double minQuantity = 0.01;
  static const double maxPercentage = 100.0;
  static const double minPercentage = 0.01;
  static const int maxTextLength = 50;
  static const int maxDescriptionLength = 200;

  // Default Values
  static const double defaultMargin = 30.0;
  static const double defaultEstimasiPorsi = 1.0;
  static const double defaultEstimasiProduksi = 30.0;
  static const String defaultUnit = 'unit';
  static const String defaultUsageUnit = '%';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 3.0;

  // Animation Duration
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Debounce Duration
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // Storage Keys
  static const String keySharedData = 'shared_calculation_data';
  static const String keyMenuHistory = 'menu_history';
  static const String keyAppSettings = 'app_settings';

  // Error Messages
  static const String errorEmptyName = 'Nama tidak boleh kosong';
  static const String errorInvalidPrice = 'Harga harus berupa angka yang valid';
  static const String errorNegativePrice = 'Harga harus lebih dari 0';
  static const String errorMaxPrice = 'Harga terlalu besar';
  static const String errorInvalidQuantity =
      'Jumlah harus berupa angka yang valid';
  static const String errorZeroQuantity = 'Jumlah harus lebih dari 0';
  static const String errorInvalidPercentage = 'Persentase harus antara 0-100%';

  // Success Messages
  static const String successDataSaved = 'Data berhasil disimpan';
  static const String successDataDeleted = 'Data berhasil dihapus';
  static const String successMenuAdded = 'Menu berhasil ditambahkan';
}
