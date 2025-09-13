// lib/utils/constants.dart - TAHAP 3 IMPROVED VERSION
class AppConstants {
  // App Info - IMPROVED BAHASA INDONESIA
  static const String appName = 'Kalkulator HPP UMKM';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Aplikasi perhitungan Harga Pokok Penjualan untuk UMKM Indonesia';

  // Validation Constants - REALISTIC LIMITS FOR INDONESIA UMKM
  static const double maxPrice = 50000000.0; // 50 juta (realistic for UMKM)
  static const double minPrice = 100.0; // Rp 100 minimum
  static const double maxQuantity = 5000.0; // 5 ribu unit (realistic)
  static const double minQuantity = 0.01; // Allow decimal
  static const double maxPercentage = 100.0; // 100%
  static const double minPercentage = 0.01; // 0.01%
  static const int maxTextLength = 50; // Nama produk/karyawan
  static const int maxDescriptionLength = 200; // Deskripsi

  // UMKM Specific Validation
  static const double minSalary = 1000000.0; // 1 juta (UMR minimum Indonesia)
  static const double maxSalary = 15000000.0; // 15 juta (realistic max)
  static const double minMarginWarning = 10.0; // Warning jika margin < 10%
  static const double maxOperationalRatio =
      50.0; // Warning jika operational > 50% dari HPP

  // Default Values - INDONESIA CONTEXT
  static const double defaultMargin = 30.0; // 30% margin standard
  static const double defaultEstimasiPorsi = 10.0; // 10 porsi per produksi
  static const double defaultEstimasiProduksi = 25.0; // 25 hari kerja per bulan
  static const String defaultUnit = 'unit'; // Unit default
  static const String defaultUsageUnit = '%'; // Persentase untuk kemudahan

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

  // Error Messages - BAHASA INDONESIA
  static const String errorEmptyName = 'Nama tidak boleh kosong';
  static const String errorInvalidPrice = 'Harga harus berupa angka yang valid';
  static const String errorNegativePrice = 'Harga harus lebih dari Rp 100';
  static const String errorMaxPrice =
      'Harga terlalu besar (maksimal Rp 50 juta)';
  static const String errorInvalidQuantity =
      'Jumlah harus berupa angka yang valid';
  static const String errorZeroQuantity = 'Jumlah harus lebih dari 0';
  static const String errorInvalidPercentage = 'Persentase harus antara 0-100%';
  static const String errorLowSalary =
      'Gaji terlalu rendah (minimal Rp 1 juta)';
  static const String errorHighSalary =
      'Gaji terlalu besar (maksimal Rp 15 juta)';

  // Success Messages - BAHASA INDONESIA
  static const String successDataSaved = 'Data berhasil disimpan';
  static const String successDataDeleted = 'Data berhasil dihapus';
  static const String successMenuAdded = 'Menu berhasil ditambahkan';

  // Warning Messages - BUSINESS LOGIC
  static const String warningLowMargin =
      'Margin terlalu rendah untuk keberlanjutan bisnis';
  static const String warningHighOperational =
      'Biaya operasional terlalu tinggi, review efisiensi';
  static const String warningPriceCompetitive =
      'Harga mungkin tidak kompetitif di pasar';

  // App Text Labels - CONSISTENT BAHASA INDONESIA
  static const String labelHPPCalculator = 'Kalkulator HPP';
  static const String labelOperationalCalculator = 'Kalkulator Operasional';
  static const String labelMenuCalculator = 'Kalkulator Menu & Profit';
  static const String labelVariableCost = 'Biaya Bahan Baku';
  static const String labelFixedCost = 'Biaya Tetap Bulanan';
  static const String labelEmployeeData = 'Data Karyawan';
  static const String labelMenuComposition = 'Komposisi Menu';
  static const String labelProfitAnalysis = 'Analisis Keuntungan';

  // Help Text - UMKM CONTEXT
  static const String helpVariableCost =
      'Biaya bahan baku yang berubah sesuai jumlah produksi';
  static const String helpFixedCost =
      'Biaya tetap yang dibayar setiap bulan (sewa, listrik, dll)';
  static const String helpOperational =
      'Biaya gaji karyawan dan operasional lainnya';
  static const String helpMargin =
      'Persentase keuntungan yang diinginkan (disarankan 25-40%)';
  static const String helpEstimation =
      'Perkiraan jumlah produksi berdasarkan pengalaman';

  // UMKM Business Types for Indonesia Context
  static const List<String> umkmTypes = [
    'Warung Makan',
    'Katering',
    'Konveksi',
    'Toko Kelontong',
    'Bengkel',
    'Salon/Barbershop',
    'Laundry',
    'Toko Kue',
    'Fotokopi & Printing',
    'Toko ATK',
    'Roti Bakar',
    'Nasi goreng',
    'Lainnya'
  ];

  // Common Indonesian Units
  static const List<String> indonesianUnits = [
    'unit', 'pcs', 'buah', // Satuan
    'kg', 'gram', 'ons', // Berat
    'liter', 'ml', // Volume
    'meter', 'cm', // Panjang
    'lembar', 'rim', // Kertas
    'pack', 'box', 'karton', // Kemasan
    'botol', 'kaleng', 'sachet', // Wadah
    '%' // Persentase
  ];
}
