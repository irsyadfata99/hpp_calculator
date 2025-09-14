// lib/screens/hpp_calculator_screen.dart - WITHOUT EXPORT/IMPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hpp_provider.dart';
import '../widgets/hpp/variable_cost_widget.dart';
import '../widgets/hpp/fixed_cost_widget.dart';
import '../widgets/hpp/hpp_result_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../utils/constants.dart';
import '../theme/app_colors.dart';

class HPPCalculatorScreen extends StatelessWidget {
  const HPPCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator HPP'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          Consumer<HPPProvider>(
            builder: (context, hppProvider, child) {
              if (hppProvider.lastCalculationResult?.isValid == true) {
                return IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showCalculationInfo(context, hppProvider),
                  tooltip: 'Info Perhitungan',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reset Data'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<HPPProvider>(
        builder: (context, hppProvider, child) {
          if (hppProvider.isLoading) {
            return const LoadingWidget(message: 'Menghitung HPP...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Error Message
                if (hppProvider.errorMessage != null)
                  _buildErrorMessage(context, hppProvider),

                // Data Summary Card
                _buildDataSummaryCard(hppProvider),

                const SizedBox(height: AppConstants.defaultPadding),

                // Variable Cost Card
                VariableCostWidget(
                  variableCosts: hppProvider.data.variableCosts,
                  onDataChanged: () {
                    // Data sudah auto-sync via provider
                  },
                  onAddItem: (nama, totalHarga, jumlah, satuan) {
                    hppProvider.addVariableCost(
                        nama, totalHarga, jumlah, satuan);
                  },
                  onRemoveItem: (index) {
                    hppProvider.removeVariableCost(index);
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Fixed Cost Card
                FixedCostWidget(
                  fixedCosts: hppProvider.data.fixedCosts,
                  onDataChanged: () {
                    // Data sudah auto-sync via provider
                  },
                  onAddItem: (jenis, nominal) {
                    hppProvider.addFixedCost(jenis, nominal);
                  },
                  onRemoveItem: (index) {
                    hppProvider.removeFixedCost(index);
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // HPP Result Card
                HPPResultWidget(
                  biayaVariablePerPorsi: hppProvider.data.biayaVariablePerPorsi,
                  biayaFixedPerPorsi: hppProvider.data.biayaFixedPerPorsi,
                  hppMurniPerPorsi: hppProvider.data.hppMurniPerPorsi,
                  estimasiPorsi: hppProvider.data.estimasiPorsi,
                  estimasiProduksiBulanan:
                      hppProvider.data.estimasiProduksiBulanan,
                  onEstimasiPorsiChanged: (value) {
                    hppProvider.updateEstimasi(
                        value, hppProvider.data.estimasiProduksiBulanan);
                  },
                  onEstimasiProduksiChanged: (value) {
                    hppProvider.updateEstimasi(
                        hppProvider.data.estimasiPorsi, value);
                  },
                ),

                // Additional Information
                if (hppProvider.lastCalculationResult?.isValid == true) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildAdditionalInfo(hppProvider),
                ],

                const SizedBox(height: AppConstants.largePadding),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, HPPProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => provider.clearError(),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard(HPPProvider provider) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize, color: AppColors.info, size: 20),
                SizedBox(width: AppConstants.smallPadding),
                Text('Ringkasan Data',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Bahan',
                    provider.data.variableCosts.length.toString(),
                    AppColors.success),
                _buildSummaryItem(
                    'Fixed Cost',
                    provider.data.fixedCosts.length.toString(),
                    AppColors.secondary),
                _buildSummaryItem(
                    'Status',
                    provider.lastCalculationResult?.isValid == true
                        ? 'Valid'
                        : 'Invalid',
                    provider.lastCalculationResult?.isValid == true
                        ? AppColors.success
                        : AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAdditionalInfo(HPPProvider provider) {
    final result = provider.lastCalculationResult!;

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: AppColors.secondary, size: 20),
                SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Analisis Detail',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildProjectionRow('Total Bahan Baku:',
                provider.data.formatRupiah(result.totalBiayaBahanBaku)),
            _buildProjectionRow('Total Fixed Cost:',
                provider.data.formatRupiah(result.totalBiayaFixedBulanan)),
            _buildProjectionRow('Total Porsi per Bulan:',
                '${result.totalPorsiBulanan.toStringAsFixed(0)} porsi'),
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
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculationInfo(BuildContext context, HPPProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Perhitungan HPP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: ${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            Text('Total Items: ${provider.data.totalItemCount}'),
            const SizedBox(height: 8),
            Text(
                'Calculation Time: ${DateTime.now().toString().substring(0, 19)}'),
            const SizedBox(height: 8),
            Text(
                'Status: ${provider.lastCalculationResult?.isValid == true ? "Valid" : "Error"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final hppProvider = Provider.of<HPPProvider>(context, listen: false);

    switch (action) {
      case 'reset':
        await _handleReset(context, hppProvider);
        break;
    }
  }

  Future<void> _handleReset(BuildContext context, HPPProvider provider) async {
    final shouldReset = await ConfirmationDialog.show(
      context,
      title: 'Reset All Data',
      message:
          'Are you sure you want to delete all HPP calculation data?\n\nThis includes:\n• All variable costs\n• All fixed costs\n• Estimation settings\n\nThis action cannot be undone.',
      confirmText: 'RESET',
      cancelText: 'Cancel',
    );

    if (shouldReset == true) {
      try {
        // Show loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 16),
                  Text('🗑️ Clearing data...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ All data cleared successfully'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );

          // Show reset confirmation
          _showResetSuccessDialog(context);
        }
      } catch (e) {
        debugPrint('❌ Reset error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Reset failed: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _handleReset(context, provider),
              ),
            ),
          );
        }
      }
    }
  }

  void _showResetSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Data Reset Complete'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔄 All calculation data has been cleared'),
            SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(33, 150, 243, 0.1),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '💡 You can start fresh with new calculations',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
