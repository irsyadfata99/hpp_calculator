// File: lib/models/karyawan_data.dart (Separated)

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

  factory KaryawanData.fromMap(Map<String, dynamic> map) {
    return KaryawanData(
      id: map['id'],
      namaKaryawan: map['nama_karyawan'],
      jabatan: map['jabatan'],
      gajiBulanan: map['gaji_bulanan'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
