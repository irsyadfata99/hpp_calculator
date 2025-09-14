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

  // FIXED: Safe string extraction with comprehensive null checks
  static String _safeGetString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;

    try {
      if (value is String) {
        return value.trim();
      }
      // Convert any other type to string safely
      return value.toString().trim();
    } catch (e) {
      print('🚨 Error parsing string from: $value -> $e');
      return defaultValue;
    }
  }

  // FIXED: Safe double parsing with comprehensive checks and explicit type handling
  static double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    try {
      // Handle direct double values
      if (value is double) {
        // Check for NaN, Infinity, and negative values
        if (value.isFinite && !value.isNaN && value >= 0) {
          return value;
        }
        return defaultValue;
      }

      // Handle integer values
      if (value is int) {
        if (value >= 0) {
          return value.toDouble();
        }
        return defaultValue;
      }

      // Handle string values
      if (value is String) {
        String cleanValue = value.trim();
        if (cleanValue.isEmpty) return defaultValue;

        // Remove currency formatting (Rp, dots, commas, spaces)
        cleanValue = cleanValue.replaceAll(RegExp(r'[Rp\s,\.]'), '');

        if (cleanValue.isEmpty) return defaultValue;

        final parsed = double.tryParse(cleanValue);
        if (parsed != null && parsed.isFinite && !parsed.isNaN && parsed >= 0) {
          return parsed;
        }
        return defaultValue;
      }

      // Handle num values (covers both int and double)
      if (value is num) {
        double doubleValue = value.toDouble();
        if (doubleValue.isFinite && !doubleValue.isNaN && doubleValue >= 0) {
          return doubleValue;
        }
        return defaultValue;
      }
    } catch (e) {
      print(
          '🚨 Error parsing double from: $value (${value.runtimeType}) -> $e');
    }

    return defaultValue;
  }

  // FIXED: Safe DateTime parsing with comprehensive error handling
  static DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      // Handle DateTime objects directly
      if (value is DateTime) {
        return value;
      }

      // Handle string representations
      if (value is String && value.isNotEmpty) {
        String cleanValue = value.trim();
        if (cleanValue.isEmpty) return DateTime.now();

        // Try parsing ISO 8601 format first
        try {
          return DateTime.parse(cleanValue);
        } catch (e) {
          print('🚨 Error parsing DateTime from ISO format: $cleanValue -> $e');

          // Try other common formats if ISO fails
          try {
            // Try parsing as milliseconds since epoch
            int? timestamp = int.tryParse(cleanValue);
            if (timestamp != null) {
              return DateTime.fromMillisecondsSinceEpoch(timestamp);
            }
          } catch (e2) {
            print(
                '🚨 Error parsing DateTime from timestamp: $cleanValue -> $e2');
          }

          return DateTime.now();
        }
      }

      // Handle integer timestamps
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (e) {
          print('🚨 Error parsing DateTime from int: $value -> $e');
          return DateTime.now();
        }
      }
    } catch (e) {
      print(
          '🚨 Error parsing DateTime from: $value (${value.runtimeType}) -> $e');
    }

    return DateTime.now();
  }

  // FIXED: Enhanced copyWith method with comprehensive null safety and validation
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
      gajiBulanan: gajiBulanan != null
          ? _safeParseDouble(gajiBulanan, this.gajiBulanan)
          : this.gajiBulanan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // FIXED: Enhanced validation with business logic
  bool get isValid {
    try {
      return id.isNotEmpty &&
          namaKaryawan.isNotEmpty &&
          namaKaryawan.length >= 2 && // Minimum 2 characters
          namaKaryawan.length <= 50 && // Maximum 50 characters
          jabatan.isNotEmpty &&
          jabatan.length >= 2 && // Minimum 2 characters
          jabatan.length <= 30 && // Maximum 30 characters
          gajiBulanan > 0 &&
          gajiBulanan.isFinite &&
          !gajiBulanan.isNaN &&
          gajiBulanan >= 100000.0 && // Minimum realistic salary (100k IDR)
          gajiBulanan <= 100000000.0; // Maximum realistic salary (100M IDR)
    } catch (e) {
      print('🚨 Error validating KaryawanData: $e');
      return false;
    }
  }

  // Additional validation for business rules
  bool get isRealisticSalary {
    return gajiBulanan >= 1000000.0 && // Minimum 1 million IDR (UMR)
        gajiBulanan <= 50000000.0; // Maximum 50 million IDR (realistic max)
  }

  // Format gaji as Rupiah string
  String get formattedGaji {
    try {
      return 'Rp ${gajiBulanan.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}';
    } catch (e) {
      print('🚨 Error formatting salary: $e');
      return 'Rp 0';
    }
  }

  // Get employee initials for display
  String get initials {
    try {
      List<String> names = namaKaryawan.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0].substring(0, 1).toUpperCase();
      }
      return 'XX';
    } catch (e) {
      print('🚨 Error generating initials: $e');
      return 'XX';
    }
  }

  @override
  String toString() {
    return 'KaryawanData(id: $id, nama: $namaKaryawan, jabatan: $jabatan, gaji: ${formattedGaji})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KaryawanData &&
        other.id == id &&
        other.namaKaryawan == namaKaryawan &&
        other.jabatan == jabatan &&
        (other.gajiBulanan - gajiBulanan).abs() <
            0.01; // Handle floating point comparison
  }

  @override
  int get hashCode => Object.hash(id, namaKaryawan, jabatan, gajiBulanan);

  // Create sample data for testing
  static KaryawanData createSample({
    String? id,
    String? nama,
    String? jabatan,
    double? gaji,
  }) {
    return KaryawanData(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      namaKaryawan: nama ?? 'Sample Employee',
      jabatan: jabatan ?? 'Staff',
      gajiBulanan: gaji ?? 2500000.0,
      createdAt: DateTime.now(),
    );
  }

  // Validate before creating instance
  static KaryawanData? createSafe({
    required String id,
    required String namaKaryawan,
    required String jabatan,
    required double gajiBulanan,
    DateTime? createdAt,
  }) {
    try {
      final karyawan = KaryawanData(
        id: id,
        namaKaryawan: namaKaryawan,
        jabatan: jabatan,
        gajiBulanan: gajiBulanan,
        createdAt: createdAt ?? DateTime.now(),
      );

      return karyawan.isValid ? karyawan : null;
    } catch (e) {
      print('🚨 Error creating KaryawanData: $e');
      return null;
    }
  }
}
