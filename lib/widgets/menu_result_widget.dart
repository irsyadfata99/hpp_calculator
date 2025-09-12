// File: lib/widgets/menu_result_widget.dart

import 'package:flutter/material.dart';
import '../services/menu_calculator_service.dart';

class MenuResultWidget extends StatelessWidget {
  final String namaMenu;
  final MenuCalculationResult? calculationResult;

  const MenuResultWidget({
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

            // Hasil Perhitungan
            if (calculationResult == null)
              _buildEmptyState()
            else if (!calculationResult!.isValid)
              _buildErrorState()
            else
              _buildValidResult(),
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
        Expanded(
          child: Text(
            namaMenu.isNotEmpty
                ? 'Perhitungan $namaMenu'
                : 'Hasil Perhitungan Menu',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.calculate, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'Masukkan nama menu dan komposisi\nuntuk melihat perhitungan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              calculationResult!.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidResult() {
    final result = calculationResult!;
    final analysis = MenuCalculatorService.analyzeMenuMargin(result);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF476EAE), Color(0xFF48B3AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Breakdown Biaya Menu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown biaya
          _buildResultRow('Biaya Bahan Baku', result.biayaBahanBakuMenu),
          _buildResultRow('Biaya Fixed (proporsi)', result.biayaFixedPerMenu),
          _buildResultRow(
              'Biaya Operational (proporsi)', result.biayaOperationalPerMenu),

          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 8),

          _buildResultRow('HPP Murni per Menu', result.hppMurniPerMenu,
              isBold: true),

          const SizedBox(height: 12),

          // Pricing dengan Margin
          _buildPricingSection(result),

          const SizedBox(height: 12),

          // Analisis Margin
          _buildAnalysisSection(analysis),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            MenuCalculatorService.formatRupiah(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(MenuCalculationResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harga Jual (+ ${result.marginPercentage.toStringAsFixed(1)}% margin)',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                MenuCalculatorService.formatRupiah(result.hargaSetelahMargin),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit per Menu',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              Text(
                MenuCalculatorService.formatRupiah(result.profitPerMenu),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(Map<String, dynamic> analysis) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getStatusColor(analysis['status']).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(analysis['status']),
              color: _getStatusColor(analysis['status']), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis['kategori'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(analysis['status']),
                    fontSize: 12,
                  ),
                ),
                Text(
                  analysis['rekomendasi'],
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(analysis['status']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
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
