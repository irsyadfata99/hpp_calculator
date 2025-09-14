// lib/models/karyawan_data.dart - FIXED NULL SAFETY VERSION

class KaryawanData {
  final String id;
  final String namaKaryawan;
  final String jabatan;
  final double gajiBulanan;
  final DateTime createdAt;

  KaryawanData({
    required this.id,
    required this.namaKaryawan,
    required this.jabatan,
    required this.gajiBulanan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_karyawan': namaKaryawan,
      'jabatan': jabatan,
      'gaji_bulanan': gajiBulanan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // FIXED: Enhanced fromMap with comprehensive null safety
  factory KaryawanData.fromMap(Map<String, dynamic> map) {
    return KaryawanData(
      id: _safeGetString(map['id'], ''),
      namaKaryawan: _safeGetString(map['nama_karyawan'], ''),
      jabatan: _safeGetString(map['jabatan'], ''),
      gajiBulanan: _safeParseDouble(map['gaji_bulanan'], 0.0),
      createdAt: _safeParseDateTime(map['created_at']),
    );
  }

  // FIXED: Safe string extraction
  static String _safeGetString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  // FIXED: Safe double parsing with comprehensive checks
  static double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    try {
      if (value is double) {
        return value.isFinite ? value : defaultValue;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        if (value.trim().isEmpty) return defaultValue;
        // Clean string dari formatting (Rp, koma, titik)
        String cleanValue = value.replaceAll(RegExp(r'[^\d\.]'), '');
        if (cleanValue.isEmpty) return defaultValue;

        final parsed = double.tryParse(cleanValue);
        return (parsed != null && parsed.isFinite && parsed >= 0)
            ? parsed
            : defaultValue;
      }
    } catch (e) {
      print('🚨 Error parsing double from: $value -> $e');
    }

    return defaultValue;
  }

  // FIXED: Safe DateTime parsing
  static DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      if (value is DateTime) {
        return value;
      }
    } catch (e) {
      print('🚨 Error parsing DateTime from: $value -> $e');
    }

    return DateTime.now();
  }

  // FIXED: Enhanced copyWith method with null safety
  KaryawanData copyWith({
    String? id,
    String? namaKaryawan,
    String? jabatan,
    double? gajiBulanan,
    DateTime? createdAt,
  }) {
    return KaryawanData(
      id: id ?? this.id,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan,
      jabatan: jabatan ?? this.jabatan,
      gajiBulanan: _safeParseDouble(gajiBulanan, this.gajiBulanan),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Validation helper
  bool get isValid {
    return id.isNotEmpty &&
        namaKaryawan.isNotEmpty &&
        jabatan.isNotEmpty &&
        gajiBulanan > 0;
  }

  @override
  String toString() {
    return 'KaryawanData(id: $id, nama: $namaKaryawan, jabatan: $jabatan, gaji: $gajiBulanan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KaryawanData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
