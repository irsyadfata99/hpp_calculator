import 'package:flutter/material.dart';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../widgets/karyawan_widget.dart';
import '../widgets/operational_cost_widget.dart';
import '../widgets/total_operational_result_widget.dart';

class OperationalCalculatorScreen extends StatefulWidget {
  final SharedCalculationData sharedData;

  const OperationalCalculatorScreen({
    super.key,
    required this.sharedData,
  });

  @override
  OperationalCalculatorScreenState createState() =>
      OperationalCalculatorScreenState();
}

class OperationalCalculatorScreenState
    extends State<OperationalCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    _hitungOperational();
  }

  void _hitungOperational() {
    setState(() {
      widget.sharedData.totalOperationalCost =
          widget.sharedData.calculateTotalOperationalCost();
      widget.sharedData.totalHargaSetelahOperational =
          widget.sharedData.calculateTotalHargaSetelahOperational();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Operational'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Karyawan Card
            KaryawanWidget(
              sharedData: widget.sharedData,
              onDataChanged: _hitungOperational,
              onAddKaryawan: (nama, jabatan, gaji) {
                setState(() {
                  widget.sharedData.karyawan = [
                    ...widget.sharedData.karyawan,
                    KaryawanData(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      namaKaryawan: nama,
                      jabatan: jabatan,
                      gajiBulanan: gaji,
                      createdAt: DateTime.now(),
                    ),
                  ];
                });
                _hitungOperational();
              },
              onRemoveKaryawan: (index) {
                setState(() {
                  List<KaryawanData> newList = [...widget.sharedData.karyawan];
                  newList.removeAt(index);
                  widget.sharedData.karyawan = newList;
                });
                _hitungOperational();
              },
            ),

            const SizedBox(height: 16),

            // 2. Operational Cost Card
            OperationalCostWidget(
              sharedData: widget.sharedData,
            ),

            const SizedBox(height: 16),

            // 3. Total Result Card
            TotalOperationalResultWidget(
              sharedData: widget.sharedData,
            ),
          ],
        ),
      ),
    );
  }
}
