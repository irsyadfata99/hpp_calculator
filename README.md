# 📊 Kalkulator HPP untuk UMKM

Aplikasi Flutter sederhana untuk menghitung HPP (Harga Pokok Penjualan) khusus pelaku UMKM.

## ✨ Fitur Utama

### **3 Card Utama:**

1. **🛒 Variable Cost Card**

   - Input nama barang, total harga pembelian, jumlah & satuan
   - Langsung input di card (tanpa dialog)
   - Perhitungan otomatis harga per satuan

2. **🏢 Fixed Cost Card**

   - Input biaya tetap bulanan (sewa, listrik, gaji, dll)
   - Perhitungan otomatis biaya per hari
   - Periode bulanan sesuai permintaan

3. **🧮 HPP Result Card (Tanpa Margin)**
   - Hasil perhitungan HPP murni
   - Input parameter produksi
   - **Rumus sesuai standar bisnis yang benar**

## 🧮 **Rumus HPP yang Digunakan:**

```
HPP Murni per Porsi = Biaya Variable per Porsi + Biaya Fixed per Porsi

Dimana:
• Biaya Variable per Porsi = Total biaya bahan per porsi
• Biaya Fixed per Porsi = Total Fixed Cost Bulanan ÷ (Produksi Bulanan × Porsi per Produksi)
```

## 🎨 **Design:**

- **Color Palette**: Primary (#476EAE), Secondary (#48B3AF)
- **Title**: Terpusat dengan spacing yang pas
- **Widget-based**: Code yang rapih dan mudah maintenance
- **User-friendly**: Cocok untuk UMKM yang tidak terlalu paham teknologi

## 🚀 **Cara Install:**

### **1. Setup Project Flutter**

```bash
flutter create hpp_calculator
cd hpp_calculator
```

### **2. Struktur Folder**

Buat struktur folder ini di `lib/`:

```
lib/
├── main.dart
├── screens/
│   └── hpp_calculator_screen.dart
└── widgets/
    ├── variable_cost_widget.dart
    ├── fixed_cost_widget.dart
    └── hpp_result_widget.dart
```

### **3. Copy File**

1. Replace `pubspec.yaml`
2. Replace `lib/main.dart`
3. Buat file di `screens/hpp_calculator_screen.dart`
4. Buat 3 file widget di folder `widgets/`

### **4. Install & Run**

```bash
flutter pub get
flutter run
```

## 📱 **Tampilan Aplikasi:**

```
┌─────────────────────────────┐
│    🧮 Kalkulator HPP        │
├─────────────────────────────┤
│                             │
│ 🛒 Variable Cost            │
│ ┌─────────────────────────┐ │
│ │ Tambah Bahan Baku:      │ │
│ │ • Nama: [_____________] │ │
│ │ • Harga: [___] [__] kg  │ │
│ │ [+ Tambah Bahan]        │ │
│ │                         │ │
│ │ Daftar:                 │ │
│ │ • Beras: 5kg - Rp50k    │ │
│ │ • Ayam: 4kg - Rp80k     │ │
│ └─────────────────────────┘ │
│                             │
│ 🏢 Fixed Cost (Bulanan)     │
│ ┌─────────────────────────┐ │
│ │ Tambah Biaya Tetap:     │ │
│ │ • Jenis: [_____________] │ │
│ │ • Nominal: [__________] │ │
│ │ [+ Tambah Biaya Tetap]  │ │
│ │                         │ │
│ │ Daftar:                 │ │
│ │ • Sewa: Rp1.5jt/bulan   │ │
│ │ • Listrik: Rp300k/bulan │ │
│ └─────────────────────────┘ │
│                             │
│ 🧮 HPP Murni               │
│ ┌─────────────────────────┐ │
│ │ Parameter:              │ │
│ │ • Porsi: [_] Produksi: [_] │
│ │                         │ │
│ │ Hasil HPP:              │ │
│ │ • Variable: Rp 12,000   │ │
│ │ • Fixed: Rp 3,000       │ │
│ │ ─────────────────────── │ │
│ │ HPP Murni: Rp 15,000    │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## 🎯 **Target User:**

Pelaku UMKM yang ingin menghitung HPP secara mudah dan akurat tanpa ribet dengan fitur yang kompleks.

## 📋 **Roadmap:**

- ✅ **Phase 1**: 3 Card HPP Calculator (SELESAI)
- 🔄 **Phase 2**: Database untuk simpan data
- 🔄 **Phase 3**: Multiple screen (menu utama, riwayat, dll)
- 🔄 **Phase 4**: Export ke Excel/PDF

---

**Mudah, Sederhana, Akurat** ✨
