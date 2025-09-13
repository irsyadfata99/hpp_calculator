import 'package:flutter/material.dart';
import '../../models/shared_calculation_data.dart';

class TotalOperationalResultWidget extends StatelessWidget {
  final SharedCalculationData sharedData;

  const TotalOperationalResultWidget({
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
            _buildHasilAkhir(),
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
            color: const Color(0xFF476EAE).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt_long,
            color: Color(0xFF476EAE),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Total Harga Setelah Operational',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF476EAE),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHasilAkhir() {
    double hppMurni = sharedData.hppMurniPerPorsi;
    double operationalPerPorsi = sharedData.calculateOperationalCostPerPorsi();
    double totalHargaAkhir = sharedData.calculateTotalHargaSetelahOperational();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF476EAE),
            Color(0xFF48B3AF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF476EAE).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Akhir Perhitungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Costs
          _buildBreakdownRow('HPP Murni per Porsi', hppMurni),
          const SizedBox(height: 8),
          _buildBreakdownRow(
              'Biaya Operational per Porsi', operationalPerPorsi),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),

          const SizedBox(height: 16),

          // Total Akhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL HARGA PER PORSI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                sharedData.formatRupiah(totalHargaAkhir),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info Tambahan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Tambahan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                    'Total per Bulan (estimasi):',
                    sharedData.formatRupiah(totalHargaAkhir *
                        sharedData.estimasiPorsi *
                        sharedData.estimasiProduksiBulanan)),
                const SizedBox(height: 4),
                _buildInfoRow('Porsi per Bulan:',
                    '${(sharedData.estimasiPorsi * sharedData.estimasiProduksiBulanan).toStringAsFixed(0)} porsi'),
                const SizedBox(height: 4),
                _buildInfoRow(
                    'Jumlah Karyawan:', '${sharedData.karyawan.length} orang'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        Text(
          sharedData.formatRupiah(value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
