// lib/screens/operational_calculator_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/operational_provider.dart';
import '../providers/hpp_provider.dart';
import '../widgets/operational/karyawan_widget.dart';
import '../widgets/operational/operational_cost_widget.dart';
import '../widgets/operational/total_operational_result_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/error_dialog.dart';
import '../utils/constants.dart';
import '../theme/app_colors.dart';

class OperationalCalculatorScreen extends StatefulWidget {
  const OperationalCalculatorScreen({super.key});

  @override
  OperationalCalculatorScreenState createState() =>
      OperationalCalculatorScreenState();
}

class OperationalCalculatorScreenState
    extends State<OperationalCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    // Setup provider-to-provider communication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderCommunication();
    });
  }

  void _setupProviderCommunication() {
    final hppProvider = Provider.of<HPPProvider>(context, listen: false);
    final operationalProvider =
        Provider.of<OperationalProvider>(context, listen: false);

    // DEBUG: Print exact values
    print('DEBUG: hppProvider.data values:');
    print('  estimasiPorsi: ${hppProvider.data.estimasiPorsi}');
    print(
        '  estimasiProduksiBulanan: ${hppProvider.data.estimasiProduksiBulanan}');
    print('  hppMurniPerPorsi: ${hppProvider.data.hppMurniPerPorsi}');
    print(
        '  type estimasiPorsi: ${hppProvider.data.estimasiPorsi.runtimeType}');
    // Update operational provider with current HPP data
    operationalProvider.updateSharedData(hppProvider.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer2<OperationalProvider, HPPProvider>(
        builder: (context, operationalProvider, hppProvider, child) {
          // Update shared data when HPP changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            operationalProvider.updateSharedData(hppProvider.data);
          });

          if (operationalProvider.isLoading) {
            return const LoadingWidget(
                message: 'Menghitung biaya operational...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Error Message
                if (operationalProvider.errorMessage != null)
                  _buildErrorMessage(operationalProvider),

                // Operational Summary Card
                _buildOperationalSummaryCard(operationalProvider),

                const SizedBox(height: AppConstants.defaultPadding),

                // Karyawan Widget with Provider
                Consumer<OperationalProvider>(
                  builder: (context, provider, child) {
                    return KaryawanWidget(
                      sharedData: provider.sharedData ?? hppProvider.data,
                      onDataChanged: () {
                        // Data changes are handled automatically by provider
                      },
                      onAddKaryawan: (nama, jabatan, gaji) {
                        provider.addKaryawan(nama, jabatan, gaji);
                      },
                      onRemoveKaryawan: (index) {
                        provider.removeKaryawan(index);
                      },
                    );
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Operational Cost Widget
                Consumer<OperationalProvider>(
                  builder: (context, provider, child) {
                    return OperationalCostWidget(
                      sharedData: provider.sharedData ?? hppProvider.data,
                    );
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Total Result Widget
                Consumer<OperationalProvider>(
                  builder: (context, provider, child) {
                    return TotalOperationalResultWidget(
                      sharedData: provider.sharedData ?? hppProvider.data,
                    );
                  },
                ),

                // Analysis Cards (if calculation is valid)
                if (operationalProvider.lastCalculationResult?.isValid ==
                    true) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildEfficiencyCard(operationalProvider),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildProjectionCard(operationalProvider),
                ],

                // Bottom padding
                const SizedBox(height: AppConstants.largePadding),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Kalkulator Operational'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      actions: [
        Consumer<OperationalProvider>(
          builder: (context, provider, child) {
            if (provider.lastCalculationResult?.isValid == true) {
              return IconButton(
                icon: const Icon(Icons.analytics),
                onPressed: () => _showAnalysisDialog(provider),
                tooltip: 'Analisis Efisiensi',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'efficiency',
              child: ListTile(
                leading: Icon(Icons.trending_up),
                title: Text('Analisis Efisiensi'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'projection',
              child: ListTile(
                leading: Icon(Icons.timeline),
                title: Text('Proyeksi Bulanan'),
                dense: true,
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('Import Data'),
                dense: true,
              ),
            ),
            PopupMenuDivider(),
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
    );
  }

  Widget _buildErrorMessage(OperationalProvider provider) {
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

  Widget _buildOperationalSummaryCard(OperationalProvider provider) {
    final totalKaryawan = provider.karyawan.length;
    // FIXED: Removed unused 'totalGaji' variable - using provider.formattedTotalGaji directly

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
                Text('Ringkasan Operational',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Karyawan', totalKaryawan.toString(), AppColors.warning),
                _buildSummaryItem('Total Gaji', provider.formattedTotalGaji,
                    AppColors.success),
                _buildSummaryItem('Rata-rata',
                    provider.formattedOperationalPerPorsi, AppColors.info),
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
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildEfficiencyCard(OperationalProvider provider) {
    final analysis = provider.getEfficiencyAnalysis();

    if (!(analysis['isAvailable'] ?? false)) {
      return const SizedBox.shrink();
    }

    final efficiency = analysis['efficiency'] ?? 'N/A';
    final efficiencyColor = _getEfficiencyColor(efficiency);

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: efficiencyColor, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                const Text('Analisis Efisiensi',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildAnalysisRow('Level Efisiensi:', efficiency, efficiencyColor),
            _buildAnalysisRow(
                'Porsi per Karyawan:',
                '${analysis['porsiPerKaryawan']?.toStringAsFixed(0) ?? '0'} porsi',
                AppColors.textPrimary),
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: efficiencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Text(
                analysis['recommendation'] ?? 'Tidak ada rekomendasi',
                style: TextStyle(fontSize: 12, color: efficiencyColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard(OperationalProvider provider) {
    final projection = provider.getProjectionAnalysis();

    if (!(projection['isAvailable'] ?? false)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: AppColors.secondary, size: 20),
                SizedBox(width: AppConstants.smallPadding),
                Text('Proyeksi Operasional',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildAnalysisRow(
                'Biaya per Hari:',
                provider
                    .formattedTotalGaji, // This should be daily, but using total for now
                AppColors.textPrimary),
            _buildAnalysisRow('Biaya per Porsi:',
                provider.formattedOperationalPerPorsi, AppColors.textPrimary),
            _buildAnalysisRow('Total per Bulan:', provider.formattedTotalGaji,
                AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(String efficiency) {
    switch (efficiency) {
      case 'Sangat Efisien':
        return AppColors.success;
      case 'Efisien':
        return Colors.lightGreen;
      case 'Cukup Efisien':
        return AppColors.info;
      case 'Kurang Efisien':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final operationalProvider =
        Provider.of<OperationalProvider>(context, listen: false);

    switch (action) {
      case 'efficiency':
        _showEfficiencyAnalysis(operationalProvider);
        break;
      case 'projection':
        _showProjectionAnalysis(operationalProvider);
        break;
      case 'export':
        await _handleExport(context, operationalProvider);
        break;
      case 'import':
        await _handleImport(context, operationalProvider);
        break;
      case 'reset':
        await _handleReset(context, operationalProvider);
        break;
    }
  }

  void _showAnalysisDialog(OperationalProvider provider) {
    final analysis = provider.getEfficiencyAnalysis();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Karyawan: ${provider.karyawanCount}'),
            const SizedBox(height: 8),
            Text('Total Gaji: ${provider.formattedTotalGaji}'),
            const SizedBox(height: 8),
            if (analysis['isAvailable'] == true) ...[
              Text('Efisiensi: ${analysis['efficiency']}'),
              const SizedBox(height: 8),
              Text(
                  'Porsi per Karyawan: ${analysis['porsiPerKaryawan']?.toStringAsFixed(1) ?? '0'}'),
            ] else ...[
              Text(analysis['message'] ?? 'Data tidak tersedia'),
            ],
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

  void _showEfficiencyAnalysis(OperationalProvider provider) {
    final analysis = provider.getEfficiencyAnalysis();

    if (!(analysis['isAvailable'] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data belum lengkap untuk analisis efisiensi'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Efisiensi Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level: ${analysis['efficiency']}'),
            const SizedBox(height: 8),
            Text(
                'Porsi per Karyawan: ${analysis['porsiPerKaryawan']?.toStringAsFixed(1)}'),
            const SizedBox(height: 8),
            Text('Rekomendasi: ${analysis['recommendation']}'),
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

  void _showProjectionAnalysis(OperationalProvider provider) {
    final projection = provider.getProjectionAnalysis();

    if (!(projection['isAvailable'] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data belum tersedia untuk proyeksi'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proyeksi Operasional Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Bulanan: ${provider.formattedTotalGaji}'),
            const SizedBox(height: 8),
            Text('Per Porsi: ${provider.formattedOperationalPerPorsi}'),
            const SizedBox(height: 8),
            Text('Jumlah Karyawan: ${provider.karyawanCount}'),
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

  Future<void> _handleExport(
      BuildContext context, OperationalProvider provider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text('📤 Preparing export...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await provider.exportData();

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Export failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Export Error',
          message: e.toString(),
          onRetry: () => _handleExport(context, provider),
        );
      }
    }
  }

  Future<void> _handleImport(
      BuildContext context, OperationalProvider provider) async {
    // Implementation would be similar to HPP screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _handleReset(
      BuildContext context, OperationalProvider provider) async {
    final shouldReset = await ConfirmationDialog.show(
      context,
      title: 'Reset Operational Data',
      message:
          'Are you sure you want to delete all operational data?\n\nThis includes:\n• All employee data\n• Salary information\n\nThis action cannot be undone.',
      confirmText: 'RESET',
      cancelText: 'Cancel',
    );

    if (shouldReset == true) {
      provider.resetData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ All operational data cleared'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}
