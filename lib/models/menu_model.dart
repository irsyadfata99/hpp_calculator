// File: lib/models/menu_model.dart

class MenuComposition {
  final String namaIngredient;
  final double jumlahDipakai;
  final String satuan;
  final double hargaPerSatuan; // Diambil dari variable costs

  MenuComposition({
    required this.namaIngredient,
    required this.jumlahDipakai,
    required this.satuan,
    required this.hargaPerSatuan,
  });

  double get totalCost => jumlahDipakai * hargaPerSatuan;

  Map<String, dynamic> toMap() {
    return {
      'nama_ingredient': namaIngredient,
      'jumlah_dipakai': jumlahDipakai,
      'satuan': satuan,
      'harga_per_satuan': hargaPerSatuan,
    };
  }

  factory MenuComposition.fromMap(Map<String, dynamic> map) {
    return MenuComposition(
      namaIngredient: map['nama_ingredient'],
      jumlahDipakai: map['jumlah_dipakai'].toDouble(),
      satuan: map['satuan'],
      hargaPerSatuan: map['harga_per_satuan'].toDouble(),
    );
  }
}

class MenuItem {
  final String id;
  final String namaMenu;
  final List<MenuComposition> komposisi;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.namaMenu,
    required this.komposisi,
    required this.createdAt,
  });

  double get totalBiayaBahanBaku {
    return komposisi.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_menu': namaMenu,
      'komposisi': komposisi.map((item) => item.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      namaMenu: map['nama_menu'],
      komposisi: (map['komposisi'] as List)
          .map((item) => MenuComposition.fromMap(item))
          .toList(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
