import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/variable_cost_widget.dart';
import '../widgets/fixed_cost_widget.dart';
import '../widgets/hpp_result_widget.dart';

class HPPCalculatorScreen extends StatefulWidget {
  @override
  _HPPCalculatorScreenState createState() => _HPPCalculatorScreenState();
}

class _HPPCalculatorScreenState extends State<HPPCalculatorScreen> {
  // Data untuk Variable Cost
  List<Map<String, dynamic>> variableCosts = [];

  // Data untuk Fixed Cost
  List<Map<String, dynamic>> fixedCosts = [];

  // Parameter produksi
  double estimasiPorsi = 1.0;
  double estimasiProduksiBulanan = 30.0;

  // Hasil perhitungan HPP
  double biayaVariablePerPorsi = 0.0;
  double biayaFixedPerPorsi = 0.0;
  double hppMurniPerPorsi = 0.0;

  @override
  void initState() {
    super.initState();
    // Mulai dengan data kosong, user input sendiri
    _hitungHPP();
  }

  // Hapus dummy data, mulai dengan data kosong
  // void _generateDummyData() {
  //   // Data kosong - user input sendiri
  // }

  // Rumus HPP sesuai gambar yang dikirim user
  void _hitungHPP() {
    // Hitung total biaya variable per porsi
    double totalBiayaVariable = 0;
    for (var item in variableCosts) {
      // Asumsi: pakai 10% dari total bahan per porsi (bisa disesuaikan)
      double hargaPerSatuan = item['totalHarga'] / item['jumlah'];
      totalBiayaVariable +=
          hargaPerSatuan * 0.1; // 0.1 = jumlah yang dipakai per porsi
    }

    // Hitung total fixed cost bulanan
    double totalFixedCostBulanan =
        fixedCosts.fold(0.0, (sum, item) => sum + item['nominal']);

    setState(() {
      // Biaya Variable per Porsi
      biayaVariablePerPorsi = totalBiayaVariable;

      // Biaya Fixed per Porsi = Total Fixed Cost Bulanan / (Estimasi Produksi Bulanan × Estimasi Porsi)
      double totalPorsiBulanan = estimasiProduksiBulanan * estimasiPorsi;
      biayaFixedPerPorsi =
          totalPorsiBulanan > 0 ? totalFixedCostBulanan / totalPorsiBulanan : 0;

      // HPP Murni = Biaya Variable per Porsi + Biaya Fixed per Porsi
      hppMurniPerPorsi = biayaVariablePerPorsi + biayaFixedPerPorsi;
    });
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalkulator HPP'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Variable Cost Card
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

            SizedBox(height: 16),

            // 2. Fixed Cost Card
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

            // 3. HPP Result Card
            HPPResultWidget(
              biayaVariablePerPorsi: biayaVariablePerPorsi,
              biayaFixedPerPorsi: biayaFixedPerPorsi,
              hppMurniPerPorsi: hppMurniPerPorsi,
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
          ],
        ),
      ),
    );
  }
}
