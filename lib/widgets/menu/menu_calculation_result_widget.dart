// File: lib/widgets/menu_calculation_result_widget.dart

import 'package:flutter/material.dart';
import '../../services/menu_calculator_service.dart';

class MenuCalculationResultWidget extends StatelessWidget {
  final String namaMenu;
  final MenuCalculationResult? calculationResult;

  const MenuCalculationResultWidget({
    super.key,
    required this.namaMenu,
    required this.calculationResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // Content
            if (calculationResult == null)
              _buildEmptyState()
            else if (!calculationResult!.isValid)
              _buildErrorState()
            else
              _buildCalculationResult(),
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
        Expanded(
          child: Text(
            namaMenu.isNotEmpty ? 'Perhitungan $namaMenu' : 'Perhitungan Menu',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF476EAE),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.pending_actions, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'Menunggu data menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tambahkan bahan untuk melihat perhitungan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error Perhitungan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  calculationResult!.errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationResult() {
    final result = calculationResult!;

    return Column(
      children: [
        // HPP Murni per Porsi
        _buildResultCard(
          title: 'HPP Murni per Porsi',
          value: result.hppMurniPerMenu,
          icon: Icons.receipt,
          color: Colors.blue,
          subtitle: 'Biaya pokok produksi',
        ),

        const SizedBox(height: 12),

        // Harga Jual + Margin
        _buildResultCard(
          title: 'Harga Jual',
          value: result.hargaSetelahMargin,
          icon: Icons.sell,
          color: Colors.green,
          subtitle:
              'Dengan margin ${result.marginPercentage.toStringAsFixed(1)}%',
        ),

        const SizedBox(height: 12),

        // Profit per Porsi
        _buildResultCard(
          title: 'Profit per Porsi',
          value: result.profitPerMenu,
          icon: Icons.trending_up,
          color: Colors.orange,
          subtitle: _getProfitPercentage(result),
        ),

        const SizedBox(height: 16),

        // Summary Info
        _buildSummaryInfo(result),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MenuCalculatorService.formatRupiah(value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo(MenuCalculationResult result) {
    final analysis = MenuCalculatorService.analyzeMenuMargin(result);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAnalysisColor(analysis['status']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                _getAnalysisColor(analysis['status']).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAnalysisIcon(analysis['status']),
            color: _getAnalysisColor(analysis['status']),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisis: ${analysis['kategori']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getAnalysisColor(analysis['status']),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  analysis['rekomendasi'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProfitPercentage(MenuCalculationResult result) {
    if (result.hargaSetelahMargin <= 0) return '';
    double percentage =
        (result.profitPerMenu / result.hargaSetelahMargin) * 100;
    return '${percentage.toStringAsFixed(1)}% dari harga jual';
  }

  Color _getAnalysisColor(String status) {
    switch (status) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'normal':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAnalysisIcon(String status) {
    switch (status) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'normal':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'danger':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
