// File: test/hpp_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hpp_calculator/services/hpp_calculator_service.dart'; // Fixed: Changed to package import

void main() {
  group('HPPCalculatorService Tests', () {
    test('Calculate HPP dengan data valid sesuai rumus gambar', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = [
        {
          'nama': 'Beras',
          'totalHarga': 50000.0,
          'jumlah': 5.0,
          'satuan': 'kg',
        },
        {
          'nama': 'Ayam',
          'totalHarga': 100000.0,
          'jumlah': 2.0,
          'satuan': 'kg',
        },
      ];

      List<Map<String, dynamic>> fixedCosts = [
        {
          'jenis': 'Sewa Tempat',
          'nominal': 1500000.0,
        },
        {
          'jenis': 'Listrik',
          'nominal': 300000.0,
        },
      ];

      double estimasiPorsiPerProduksi = 10.0; // 10 porsi per produksi
      double estimasiProduksiBulanan = 30.0; // 30 kali produksi per bulan

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Assert
      expect(result.isValid, true);
      expect(result.errorMessage, null);

      // Total Biaya Bahan Baku = 50000 + 100000 = 150000
      expect(result.totalBiayaBahanBaku, 150000.0);

      // Biaya Variabel per Porsi = 150000 ÷ 10 = 15000
      expect(result.biayaVariablePerPorsi, 15000.0);

      // Total Fixed Cost Bulanan = 1500000 + 300000 = 1800000
      expect(result.totalBiayaFixedBulanan, 1800000.0);

      // Total Porsi Bulanan = 10 × 30 = 300 porsi
      expect(result.totalPorsiBulanan, 300.0);

      // Biaya Fixed per Porsi = 1800000 ÷ 300 = 6000
      expect(result.biayaFixedPerPorsi, 6000.0);

      // HPP Murni = 15000 + 6000 = 21000
      expect(result.hppMurniPerPorsi, 21000.0);
    });

    test('Handle error ketika estimasi porsi = 0', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = [
        {'nama': 'Beras', 'totalHarga': 50000.0, 'jumlah': 5.0, 'satuan': 'kg'}
      ];
      List<Map<String, dynamic>> fixedCosts = [];

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: 0.0, // Invalid
        estimasiProduksiBulanan: 30.0,
      );

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage,
          'Estimasi Porsi per Produksi harus lebih besar dari 0');
    });

    test('Handle error ketika estimasi produksi bulanan = 0', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = [
        {'nama': 'Beras', 'totalHarga': 50000.0, 'jumlah': 5.0, 'satuan': 'kg'}
      ];
      List<Map<String, dynamic>> fixedCosts = [];

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: 10.0,
        estimasiProduksiBulanan: 0.0, // Invalid
      );

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage,
          'Estimasi Produksi Bulanan harus lebih besar dari 0');
    });

    test('Handle empty variable costs', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = []; // Empty
      List<Map<String, dynamic>> fixedCosts = [
        {'jenis': 'Sewa', 'nominal': 1000000.0}
      ];

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: 10.0,
        estimasiProduksiBulanan: 30.0,
      );

      // Assert
      expect(result.isValid, true);
      expect(result.totalBiayaBahanBaku, 0.0);
      expect(result.biayaVariablePerPorsi, 0.0); // 0 / 10 = 0
      // Fixed: Corrected moreOrLessEquals usage
      expect(result.biayaFixedPerPorsi, closeTo(3333.33, 0.01));
    });

    test('Handle empty fixed costs', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = [
        {
          'nama': 'Beras',
          'totalHarga': 100000.0,
          'jumlah': 10.0,
          'satuan': 'kg'
        }
      ];
      List<Map<String, dynamic>> fixedCosts = []; // Empty

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: 10.0,
        estimasiProduksiBulanan: 30.0,
      );

      // Assert
      expect(result.isValid, true);
      expect(result.totalBiayaFixedBulanan, 0.0);
      expect(result.biayaFixedPerPorsi, 0.0);
      expect(result.biayaVariablePerPorsi, 10000.0); // 100000 / 10
      expect(result.hppMurniPerPorsi, 10000.0); // 10000 + 0
    });

    test('Handle data dengan nilai negatif dalam variableCosts', () {
      // Arrange
      List<Map<String, dynamic>> variableCosts = [
        {'nama': 'Beras', 'totalHarga': 50000.0, 'jumlah': 5.0, 'satuan': 'kg'},
        {
          'nama': 'Item Invalid',
          'totalHarga': -10000.0,
          'jumlah': 1.0,
          'satuan': 'pcs'
        }, // Negatif
      ];
      List<Map<String, dynamic>> fixedCosts = [];

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: 10.0,
        estimasiProduksiBulanan: 30.0,
      );

      // Assert
      expect(result.isValid, true);
      // Item dengan nilai negatif akan di-skip, jadi hanya beras yang dihitung
      expect(result.totalBiayaBahanBaku, 50000.0);
    });

    test('Format rupiah berfungsi dengan benar', () {
      // Test berbagai nilai
      expect(HPPCalculatorService.formatRupiah(1000), 'Rp 1.000');
      expect(HPPCalculatorService.formatRupiah(1000000), 'Rp 1.000.000');
      expect(HPPCalculatorService.formatRupiah(1234567), 'Rp 1.234.567');
      expect(HPPCalculatorService.formatRupiah(0), 'Rp 0');
      expect(HPPCalculatorService.formatRupiah(500), 'Rp 500');

      // Test edge cases
      expect(HPPCalculatorService.formatRupiah(double.nan), 'Rp 0');
      expect(HPPCalculatorService.formatRupiah(double.infinity), 'Rp 0');
    });

    test('Calculate harga per satuan', () {
      // Normal case
      expect(
          HPPCalculatorService.calculateHargaPerSatuan(
              totalHarga: 100000.0, jumlah: 5.0),
          20000.0);

      // Edge case: jumlah = 0
      expect(
          HPPCalculatorService.calculateHargaPerSatuan(
              totalHarga: 100000.0, jumlah: 0.0),
          0.0);

      // Edge case: jumlah negatif
      expect(
          HPPCalculatorService.calculateHargaPerSatuan(
              totalHarga: 100000.0, jumlah: -1.0),
          0.0);
    });

    test('Validasi data complete', () {
      List<Map<String, dynamic>> variableCosts = [
        {'nama': 'Beras', 'totalHarga': 50000.0, 'jumlah': 5.0, 'satuan': 'kg'}
      ];

      // Complete data
      expect(
          HPPCalculatorService.isDataComplete(
            variableCosts: variableCosts,
            estimasiPorsiPerProduksi: 10.0,
            estimasiProduksiBulanan: 30.0,
          ),
          true);

      // Incomplete: empty variable costs
      expect(
          HPPCalculatorService.isDataComplete(
            variableCosts: [],
            estimasiPorsiPerProduksi: 10.0,
            estimasiProduksiBulanan: 30.0,
          ),
          false);

      // Incomplete: estimasi porsi = 0
      expect(
          HPPCalculatorService.isDataComplete(
            variableCosts: variableCosts,
            estimasiPorsiPerProduksi: 0.0,
            estimasiProduksiBulanan: 30.0,
          ),
          false);
    });

    test('Monthly projection calculation', () {
      // Arrange
      double hppMurniPerPorsi = 20000.0;
      double estimasiPorsiPerProduksi = 10.0;
      double estimasiProduksiBulanan = 30.0;

      // Act
      final projection = HPPCalculatorService.calculateMonthlyProjection(
        hppMurniPerPorsi: hppMurniPerPorsi,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Assert
      expect(projection['totalPorsiBulanan'], 300.0); // 10 × 30
      expect(projection['totalHPPBulanan'], 6000000.0); // 20000 × 300
      expect(projection['hppPerHari'], 200000.0); // 6000000 / 30
    });

    test('Rumus sesuai dengan gambar - Test Case Realistis', () {
      // Test case yang mirip dengan kondisi nyata warung makan
      List<Map<String, dynamic>> variableCosts = [
        {
          'nama': 'Beras 10kg',
          'totalHarga': 120000.0,
          'jumlah': 10.0,
          'satuan': 'kg'
        },
        {
          'nama': 'Ayam 3kg',
          'totalHarga': 90000.0,
          'jumlah': 3.0,
          'satuan': 'kg'
        },
        {
          'nama': 'Sayuran',
          'totalHarga': 50000.0,
          'jumlah': 5.0,
          'satuan': 'kg'
        },
        {
          'nama': 'Bumbu & Rempah',
          'totalHarga': 40000.0,
          'jumlah': 1.0,
          'satuan': 'paket'
        },
      ];

      List<Map<String, dynamic>> fixedCosts = [
        {'jenis': 'Sewa Warung', 'nominal': 2000000.0},
        {'jenis': 'Listrik & Air', 'nominal': 500000.0},
        {'jenis': 'Gas', 'nominal': 300000.0},
      ];

      // Asumsi: sekali masak bisa untuk 50 porsi, masak 25 kali per bulan
      double estimasiPorsiPerProduksi = 50.0;
      double estimasiProduksiBulanan = 25.0;

      // Act
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Assert
      expect(result.isValid, true);

      // Total Biaya Bahan Baku = 120000 + 90000 + 50000 + 40000 = 300000
      expect(result.totalBiayaBahanBaku, 300000.0);

      // Biaya Variabel per Porsi = 300000 ÷ 50 = 6000
      expect(result.biayaVariablePerPorsi, 6000.0);

      // Total Fixed Cost = 2000000 + 500000 + 300000 = 2800000
      expect(result.totalBiayaFixedBulanan, 2800000.0);

      // Total Porsi Bulanan = 50 × 25 = 1250
      expect(result.totalPorsiBulanan, 1250.0);

      // Biaya Fixed per Porsi = 2800000 ÷ 1250 = 2240
      expect(result.biayaFixedPerPorsi, 2240.0);

      // HPP Murni = 6000 + 2240 = 8240
      expect(result.hppMurniPerPorsi, 8240.0);

      // Fixed: Removed print statements for production code
      // Results can be verified through the expect statements above
    });
  });
}
