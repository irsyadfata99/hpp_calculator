import 'package:flutter/material.dart';

class HPPResultWidget extends StatelessWidget {
  final double biayaVariablePerPorsi;
  final double biayaFixedPerPorsi;
  final double hppMurniPerPorsi;
  final double estimasiPorsi;
  final double estimasiProduksiBulanan;
  final Function(double) onEstimasiPorsiChanged;
  final Function(double) onEstimasiProduksiChanged;

  const HPPResultWidget({
    super.key,
    required this.biayaVariablePerPorsi,
    required this.biayaFixedPerPorsi,
    required this.hppMurniPerPorsi,
    required this.estimasiPorsi,
    required this.estimasiProduksiBulanan,
    required this.onEstimasiPorsiChanged,
    required this.onEstimasiProduksiChanged,
  });

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

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
            _buildParameterInput(),
            const SizedBox(height: 20),
            _buildHasil(),
            const SizedBox(height: 16),
            _buildInfoTambahan(),
            const SizedBox(height: 8),
            _buildRumusInfo(),
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
            Icons.calculate,
            color: Color(0xFF476EAE),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'HPP Murni (Tanpa Margin)',
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

  Widget _buildParameterInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Parameter Produksi:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildInputField('Estimasi Porsi per Produksi',
                    estimasiPorsi, 'porsi', onEstimasiPorsiChanged)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildInputField(
                    'Frekuensi Produksi per Bulan',
                    estimasiProduksiBulanan,
                    'kali',
                    onEstimasiProduksiChanged)),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(
      String label, double value, String suffix, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: suffix,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (text) {
            double? newValue = double.tryParse(text);
            if (newValue != null && newValue > 0) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHasil() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEEF2FF), // Light blue
            Color(0xFFECFDFD), // Light teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF476EAE).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Perhitungan HPP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF476EAE),
            ),
          ),
          const SizedBox(height: 12),

          _buildResultRow('Biaya Variable per Porsi', biayaVariablePerPorsi,
              Colors.green, Icons.trending_up),
          const SizedBox(height: 8),
          _buildResultRow('Biaya Fixed per Porsi', biayaFixedPerPorsi,
              Color(0xFF48B3AF), Icons.account_balance),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // HPP Murni Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF476EAE).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded,
                        color: Color(0xFF476EAE), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'HPP Murni per Porsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF476EAE),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatRupiah(hppMurniPerPorsi),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF476EAE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, double value, Color color, IconData icon) {
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
          _formatRupiah(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTambahan() {
    double totalPorsiBulanan = estimasiPorsi * estimasiProduksiBulanan;
    double hppBulanan =
        hppMurniPerPorsi * estimasiPorsi * estimasiProduksiBulanan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 6),
              Text(
                'Informasi Produksi',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Total Porsi per Bulan:',
              '${totalPorsiBulanan.toStringAsFixed(0)} porsi'),
          const SizedBox(height: 4),
          _buildInfoRow('HPP per Bulan (estimasi):', _formatRupiah(hppBulanan)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF476EAE)),
        ),
      ],
    );
  }

  Widget _buildRumusInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Rumus HPP yang Digunakan:',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            '• Biaya Variabel per Porsi = Total Biaya Bahan Baku ÷ Estimasi Porsi per Produksi',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            '• Biaya Fixed per Porsi = Total Biaya Fixed Bulanan ÷ Total Porsi Bulanan',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            '• HPP Murni = Biaya Variabel per Porsi + Biaya Fixed per Porsi',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
