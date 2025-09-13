// lib/utils/formatters.dart
class AppFormatters {
  /// Format rupiah dengan pemisah ribuan
  static String formatRupiah(double amount) {
    if (amount.isNaN || amount.isInfinite) {
      return 'Rp 0';
    }
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// Format persentase
  static String formatPercentage(double percentage) {
    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    } else {
      return '${percentage.toStringAsFixed(1)}%';
    }
  }

  /// Parse angka dari string yang sudah diformat
  static double? parseFormattedNumber(String formatted) {
    String clean = formatted.replaceAll(RegExp(r'[^\d\.]'), '');
    return double.tryParse(clean);
  }
}
