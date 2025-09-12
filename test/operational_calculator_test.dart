// File: test/operational_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hpp_calculator/services/operational_calculator_service.dart';
import 'package:hpp_calculator/models/karyawan_data.dart';

void main() {
  group('OperationalCalculatorService Tests', () {
    // Sample data untuk testing
    List<KaryawanData> sampleKaryawan = [
      KaryawanData(
        id: '1',
        namaKaryawan: 'Budi',
        jabatan: 'Kasir',
        gajiBulanan: 2500000.0,
        createdAt: DateTime.now(),
      ),
      KaryawanData(
        id: '2',
        namaKaryawan: 'Siti',
        jabatan: 'Koki',
        gajiBulanan: 3000000.0,
        createdAt: DateTime.now(),
      ),
    ];

    test('Calculate total gaji bulanan dengan data valid', () {
      // Act
      double totalGaji = OperationalCalculatorService.calculateTotalGajiBulanan(
          sampleKaryawan);

      // Assert
      expect(totalGaji, 5500000.0); // 2500000 + 3000000
    });

    test('Calculate total gaji bulanan dengan list kosong', () {
      // Act
      double totalGaji =
          OperationalCalculatorService.calculateTotalGajiBulanan([]);

      // Assert
      expect(totalGaji, 0.0);
    });

    test('Calculate operational cost per porsi dengan data valid', () {
      // Arrange
      double estimasiPorsiPerProduksi = 50.0;
      double estimasiProduksiBulanan = 25.0;

      // Act
      double operationalPerPorsi =
          OperationalCalculatorService.calculateOperationalCostPerPorsi(
        karyawan: sampleKaryawan,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Assert
      // Total Gaji = 5500000, Total Porsi = 50 × 25 = 1250
      // Operational per Porsi = 5500000 ÷ 1250 = 4400
      expect(operationalPerPorsi, 4400.0);
    });

    test('Calculate operational cost per porsi dengan estimasi porsi = 0', () {
      // Act
      double operationalPerPorsi =
          OperationalCalculatorService.calculateOperationalCostPerPorsi(
        karyawan: sampleKaryawan,
        estimasiPorsiPerProduksi: 0.0,
        estimasiProduksiBulanan: 25.0,
      );

      // Assert
      expect(operationalPerPorsi, 0.0);
    });

    test('Calculate total harga setelah operational', () {
      // Arrange
      double hppMurni = 15000.0;
      double operationalCost = 4400.0;

      // Act
      double totalHarga =
          OperationalCalculatorService.calculateTotalHargaSetelahOperational(
        hppMurniPerPorsi: hppMurni,
        operationalCostPerPorsi: operationalCost,
      );

      // Assert
      expect(totalHarga, 19400.0); // 15000 + 4400
    });

    test('Calculate operational cost lengkap dengan data valid', () {
      // Act
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: sampleKaryawan,
        hppMurniPerPorsi: 15000.0,
        estimasiPorsiPerProduksi: 50.0,
        estimasiProduksiBulanan: 25.0,
      );

      // Assert
      expect(result.isValid, true);
      expect(result.errorMessage, null);
      expect(result.totalGajiBulanan, 5500000.0);
      expect(result.operationalCostPerPorsi, 4400.0);
      expect(result.totalHargaSetelahOperational, 19400.0); // 15000 + 4400
      expect(result.totalPorsiBulanan, 1250.0); // 50 × 25
      expect(result.jumlahKaryawan, 2);
    });

    test('Handle error ketika estimasi porsi = 0', () {
      // Act
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: sampleKaryawan,
        hppMurniPerPorsi: 15000.0,
        estimasiPorsiPerProduksi: 0.0,
        estimasiProduksiBulanan: 25.0,
      );

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage,
          'Estimasi Porsi per Produksi harus lebih besar dari 0');
    });

    test('Handle error ketika estimasi produksi bulanan = 0', () {
      // Act
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: sampleKaryawan,
        hppMurniPerPorsi: 15000.0,
        estimasiPorsiPerProduksi: 50.0,
        estimasiProduksiBulanan: 0.0,
      );

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage,
          'Estimasi Produksi Bulanan harus lebih besar dari 0');
    });

    test('Handle karyawan kosong', () {
      // Act
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: [],
        hppMurniPerPorsi: 15000.0,
        estimasiPorsiPerProduksi: 50.0,
        estimasiProduksiBulanan: 25.0,
      );

      // Assert
      expect(result.isValid, true);
      expect(result.totalGajiBulanan, 0.0);
      expect(result.operationalCostPerPorsi, 0.0);
      expect(result.totalHargaSetelahOperational, 15000.0); // HPP saja
      expect(result.jumlahKaryawan, 0);
    });

    test('Format rupiah berfungsi dengan benar', () {
      // Test berbagai nilai
      expect(
          OperationalCalculatorService.formatRupiah(2500000), 'Rp 2.500.000');
      expect(OperationalCalculatorService.formatRupiah(4400), 'Rp 4.400');
      expect(OperationalCalculatorService.formatRupiah(0), 'Rp 0');

      // Test edge cases
      expect(OperationalCalculatorService.formatRupiah(double.nan), 'Rp 0');
      expect(
          OperationalCalculatorService.formatRupiah(double.infinity), 'Rp 0');
    });

    test('Calculate operational projection', () {
      // Act
      final projection =
          OperationalCalculatorService.calculateOperationalProjection(
        karyawan: sampleKaryawan,
        estimasiPorsiPerProduksi: 50.0,
        estimasiProduksiBulanan: 25.0,
      );

      // Assert
      expect(projection['totalGajiBulanan'], 5500000.0);
      expect(projection['operationalPerPorsi'], 4400.0);
      expect(projection['operationalPerHari'],
          closeTo(183333.33, 0.01)); // 5500000 / 30
      expect(projection['jumlahKaryawan'], 2);
      expect(projection['totalPorsiBulanan'], 1250.0);
    });

    test('Analyze karyawan efficiency', () {
      // Act
      final analysis = OperationalCalculatorService.analyzeKaryawanEfficiency(
        karyawan: sampleKaryawan,
        totalPorsiBulanan: 1250.0,
      );

      // Assert
      expect(analysis['averageGajiPerKaryawan'], 2750000.0); // 5500000 / 2
      expect(analysis['porsiPerKaryawan'], 625.0); // 1250 / 2
      expect(analysis['efficiency'],
          'Sangat Efisien'); // >= 400 porsi per karyawan
    });

    test('Analyze karyawan efficiency dengan data kosong', () {
      // Act
      final analysis = OperationalCalculatorService.analyzeKaryawanEfficiency(
        karyawan: [],
        totalPorsiBulanan: 1250.0,
      );

      // Assert
      expect(analysis['averageGajiPerKaryawan'], 0.0);
      expect(analysis['porsiPerKaryawan'], 0.0);
      expect(analysis['efficiency'], 'N/A');
    });

    test('Validasi data karyawan complete', () {
      // Complete data
      expect(
          OperationalCalculatorService.isKaryawanDataComplete(sampleKaryawan),
          true);

      // Empty list
      expect(OperationalCalculatorService.isKaryawanDataComplete([]), false);

      // Karyawan dengan data tidak lengkap
      List<KaryawanData> incompleteKaryawan = [
        KaryawanData(
          id: '1',
          namaKaryawan: '',
          jabatan: 'Kasir',
          gajiBulanan: 2500000.0,
          createdAt: DateTime.now(),
        ),
      ];

      expect(
          OperationalCalculatorService.isKaryawanDataComplete(
              incompleteKaryawan),
          false);
    });

    test('Test case realistis warung makan', () {
      // Sample data realistis
      List<KaryawanData> karyawanWarung = [
        KaryawanData(
          id: '1',
          namaKaryawan: 'Pak Budi',
          jabatan: 'Koki Utama',
          gajiBulanan: 3500000.0,
          createdAt: DateTime.now(),
        ),
        KaryawanData(
          id: '2',
          namaKaryawan: 'Mbak Sari',
          jabatan: 'Kasir',
          gajiBulanan: 2800000.0,
          createdAt: DateTime.now(),
        ),
        KaryawanData(
          id: '3',
          namaKaryawan: 'Deni',
          jabatan: 'Pelayan',
          gajiBulanan: 2200000.0,
          createdAt: DateTime.now(),
        ),
      ];

      double hppMurni = 8240.0; // Dari test HPP sebelumnya
      double estimasiPorsiPerProduksi = 50.0;
      double estimasiProduksiBulanan = 25.0;

      // Act
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: karyawanWarung,
        hppMurniPerPorsi: hppMurni,
        estimasiPorsiPerProduksi: estimasiPorsiPerProduksi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      // Assert
      expect(result.isValid, true);

      // Total Gaji = 3500000 + 2800000 + 2200000 = 8500000
      expect(result.totalGajiBulanan, 8500000.0);

      // Total Porsi = 50 × 25 = 1250
      expect(result.totalPorsiBulanan, 1250.0);

      // Operational per Porsi = 8500000 ÷ 1250 = 6800
      expect(result.operationalCostPerPorsi, 6800.0);

      // Total Harga = 8240 + 6800 = 15040
      expect(result.totalHargaSetelahOperational, 15040.0);

      expect(result.jumlahKaryawan, 3);
    });
  });
}
