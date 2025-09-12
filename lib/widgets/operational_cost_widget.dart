import 'package:flutter/material.dart';
import '../models/karyawan_data.dart';

class OperationalCostWidget extends StatelessWidget {
  final SharedCalculationData sharedData;

  const OperationalCostWidget({
    super.key,
    required this.sharedData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildRingkasan(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF48B3AF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.analytics,
            color: Color(0xFF48B3AF),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Biaya Operational',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF48B3AF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasan() {
    double totalOperational = sharedData.totalOperationalCost;
    double operationalPerPorsi = sharedData.calculateOperationalCostPerPorsi();
    double totalPorsiBulanan =
        sharedData.estimasiPorsi * sharedData.estimasiProduksiBulanan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFECFDFD), // Light teal
            Color(0xFFEEF2FF), // Light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF48B3AF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Biaya Operational',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF48B3AF),
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            'Total Gaji Karyawan/Bulan',
            sharedData.formatRupiah(totalOperational),
            Colors.orange,
            Icons.people,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            'Biaya Operational per Porsi',
            sharedData.formatRupiah(operationalPerPorsi),
            const Color(0xFF48B3AF),
            Icons.calculate,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Detail Perhitungan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildInfoRow('Total Porsi/Bulan:',
                    '${totalPorsiBulanan.toStringAsFixed(0)} porsi'),
                const SizedBox(height: 2),
                _buildInfoRow(
                    'Jumlah Karyawan:', '${sharedData.karyawan.length} orang'),
                const SizedBox(height: 2),
                Text(
                  'Formula: Total Gaji ÷ Total Porsi Bulanan',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Color(0xFF48B3AF)),
        ),
      ],
    );
  }
}
