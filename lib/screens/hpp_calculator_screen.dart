// File: lib/screens/hpp_calculator_screen.dart (Refactored)

import 'package:flutter/material.dart';
import '../models/shared_calculation_data.dart';
import '../services/hpp_calculator_service.dart';
import '../widgets/variable_cost_widget.dart';
import '../widgets/fixed_cost_widget.dart';
import '../widgets/hpp_result_widget.dart';

class HPPCalculatorScreen extends StatefulWidget {
  final SharedCalculationData sharedData;
  final Function(SharedCalculationData) onDataChanged;

  const HPPCalculatorScreen({
    super.key,
    required this.sharedData,
    required this.onDataChanged,
  });

  @override
  HPPCalculatorScreenState createState() => HPPCalculatorScreenState();
}

class HPPCalculatorScreenState extends State<HPPCalculatorScreen> {
  late List<Map<String, dynamic>> variableCosts;
  late List<Map<String, dynamic>> fixedCosts;
  late double estimasiPorsi;
  late double estimasiProduksiBulanan;

  // Hasil perhitungan HPP menggunakan service
  HPPCalculationResult? calculationResult;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Ambil data dari shared data atau mulai dengan data kosong
    variableCosts = List.from(widget.sharedData.variableCosts);
    fixedCosts = List.from(widget.sharedData.fixedCosts);
    estimasiPorsi = widget.sharedData.estimasiPorsi;
    estimasiProduksiBulanan = widget.sharedData.estimasiProduksiBulanan;

    _hitungHPP();
  }

  void _hitungHPP() {
    try {
      // Gunakan HPPCalculatorService untuk perhitungan yang benar
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
        estimasiPorsiPerProduksi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksiBulanan,
      );

      setState(() {
        calculationResult = result;
        errorMessage = result.isValid ? null : result.errorMessage;
      });

      // Update shared data SETELAH setState selesai
      // Menggunakan post-frame callback untuk menghindari setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SharedCalculationData newData = SharedCalculationData(
          variableCosts: variableCosts,
          fixedCosts: fixedCosts,
          estimasiPorsi: estimasiPorsi,
          estimasiProduksiBulanan: estimasiProduksiBulanan,
          hppMurniPerPorsi: result.hppMurniPerPorsi,
          biayaVariablePerPorsi: result.biayaVariablePerPorsi,
          biayaFixedPerPorsi: result.biayaFixedPerPorsi,
          karyawan: widget.sharedData.karyawan,
          totalOperationalCost: widget.sharedData.totalOperationalCost,
          totalHargaSetelahOperational:
              widget.sharedData.totalHargaSetelahOperational,
        );

        widget.onDataChanged(newData);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error dalam perhitungan: ${e.toString()}';
        calculationResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HPP Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Error Message jika ada
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Variable Cost Card
            VariableCostWidget(
              variableCosts: variableCosts,
              onDataChanged: () {
                _hitungHPP();
              },
              onAddItem: (nama, totalHarga, jumlah, satuan) {
                setState(() {
                  variableCosts.add({
                    'nama': nama,
                    'totalHarga': totalHarga,
                    'jumlah': jumlah,
                    'satuan': satuan,
                  });
                });
                _hitungHPP();
              },
              onRemoveItem: (index) {
                setState(() {
                  variableCosts.removeAt(index);
                });
                _hitungHPP();
              },
            ),

            const SizedBox(height: 16),

            // Fixed Cost Card
            FixedCostWidget(
              fixedCosts: fixedCosts,
              onDataChanged: () {
                _hitungHPP();
              },
              onAddItem: (jenis, nominal) {
                setState(() {
                  fixedCosts.add({
                    'jenis': jenis,
                    'nominal': nominal,
                  });
                });
                _hitungHPP();
              },
              onRemoveItem: (index) {
                setState(() {
                  fixedCosts.removeAt(index);
                });
                _hitungHPP();
              },
            ),

            const SizedBox(height: 16),

            // HPP Result Card menggunakan hasil dari service
            HPPResultWidget(
              biayaVariablePerPorsi:
                  calculationResult?.biayaVariablePerPorsi ?? 0.0,
              biayaFixedPerPorsi: calculationResult?.biayaFixedPerPorsi ?? 0.0,
              hppMurniPerPorsi: calculationResult?.hppMurniPerPorsi ?? 0.0,
              estimasiPorsi: estimasiPorsi,
              estimasiProduksiBulanan: estimasiProduksiBulanan,
              onEstimasiPorsiChanged: (value) {
                setState(() {
                  estimasiPorsi = value;
                });
                _hitungHPP();
              },
              onEstimasiProduksiChanged: (value) {
                setState(() {
                  estimasiProduksiBulanan = value;
                });
                _hitungHPP();
              },
            ),

            // Informasi tambahan dari service
            if (calculationResult != null && calculationResult!.isValid) ...[
              const SizedBox(height: 16),
              _buildAdditionalInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final projection = HPPCalculatorService.calculateMonthlyProjection(
      hppMurniPerPorsi: calculationResult!.hppMurniPerPorsi,
      estimasiPorsiPerProduksi: estimasiPorsi,
      estimasiProduksiBulanan: estimasiProduksiBulanan,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: Color(0xFF48B3AF), size: 20),
                SizedBox(width: 8),
                Text(
                  'Proyeksi Bulanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF48B3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProjectionRow(
                'Total Bahan Baku:',
                HPPCalculatorService.formatRupiah(
                    calculationResult!.totalBiayaBahanBaku)),
            _buildProjectionRow(
                'Total Fixed Cost:',
                HPPCalculatorService.formatRupiah(
                    calculationResult!.totalBiayaFixedBulanan)),
            _buildProjectionRow('Total Porsi per Bulan:',
                '${projection['totalPorsiBulanan']!.toStringAsFixed(0)} porsi'),
            _buildProjectionRow(
                'Estimasi HPP per Bulan:',
                HPPCalculatorService.formatRupiah(
                    projection['totalHPPBulanan']!)),
            _buildProjectionRow('Estimasi HPP per Hari:',
                HPPCalculatorService.formatRupiah(projection['hppPerHari']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF476EAE),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
