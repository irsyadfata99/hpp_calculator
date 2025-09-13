// lib/screens/hpp_calculator_screen.dart - FULL COMPLETE VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
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

  // ===============================================
  // MENU ACTIONS - EXPORT/IMPORT/RESET
  // ===============================================

  void _handleMenuAction(BuildContext context, String action) async {
    final hppProvider = Provider.of<HPPProvider>(context, listen: false);

    switch (action) {
      case 'export':
        await _handleExport(context, hppProvider);
        break;
      case 'import':
        await _handleImport(context, hppProvider);
        break;
      case 'reset':
        await _handleReset(context, hppProvider);
        break;
    }
  }

  Future<void> _handleExport(BuildContext context, HPPProvider provider) async {
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
                Text('📤 Preparing export...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final jsonData = await provider.exportData();
      if (jsonData != null) {
        // Prepare file content dengan proper formatting
        final formattedJson =
            const JsonEncoder.withIndent('  ').convert(json.decode(jsonData));

        // Generate timestamp for logging only
        final timestamp = DateTime.now()
            .toIso8601String()
            .substring(0, 19)
            .replaceAll(':', '-');
        debugPrint('📤 Exporting with timestamp: $timestamp');

        // Share the file using share_plus
        await Share.share(
          formattedJson,
          subject: 'HPP Calculator Data Export',
        );

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Data exported successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Show info dialog dengan details
        if (context.mounted) {
          _showExportSuccessDialog(
              context, formattedJson.length, provider.data.totalItemCount);
        }
      } else {
        throw Exception('Export returned null');
      }
    } catch (e) {
      debugPrint('❌ Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _handleExport(context, provider),
            ),
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog(
      BuildContext context, int dataSize, int itemCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Export Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Items exported: $itemCount'),
            const SizedBox(height: 4),
            Text('📁 Data size: ${(dataSize / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Tip: Save the shared file to your device for backup',
                style: TextStyle(fontSize: 12),
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

  Future<void> _handleImport(BuildContext context, HPPProvider provider) async {
    try {
      // Show file picker - WEB & MOBILE COMPATIBLE
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true, // IMPORTANT: This ensures bytes are loaded for web
      );

      if (result != null && result.files.single.bytes != null) {
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
                  Text('📥 Importing data...'),
                ],
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Read file content - WORKS ON WEB & MOBILE
        final file = result.files.single;
        String jsonString;

        try {
          // Use bytes instead of path (web compatible)
          jsonString = String.fromCharCodes(file.bytes!);
        } catch (e) {
          throw Exception('Could not read file content');
        }

        // Validate JSON format
        try {
          json.decode(jsonString);
        } catch (e) {
          throw Exception('Invalid JSON format');
        }

        // Import data through provider
        final success = await provider.importData(jsonString);

        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Data imported successfully!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );

            // Show success dialog
            _showImportSuccessDialog(
                context, file.name, provider.data.totalItemCount);
          }
        } else {
          throw Exception('Import validation failed');
        }
      } else if (result != null && result.files.single.bytes == null) {
        // Handle case where file was selected but bytes are null
        throw Exception(
            'Could not read file content. Please try selecting a smaller file.');
      } else {
        // User cancelled file selection
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📁 File selection cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Import error: $e');
      if (context.mounted) {
        // Show user-friendly error messages
        String errorMessage = e.toString();
        if (errorMessage.contains('JSON')) {
          errorMessage =
              'Invalid file format. Please select a valid JSON backup file.';
        } else if (errorMessage.contains('read file')) {
          errorMessage =
              'Could not read file. Try selecting a smaller file or refresh the page.';
        } else if (errorMessage.contains('validation failed')) {
          errorMessage = 'File format is not compatible with this app version.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _handleImport(context, provider),
            ),
          ),
        );
      }
    }
  }

  void _showImportSuccessDialog(
      BuildContext context, String fileName, int itemCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Import Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📁 File: $fileName'),
            const SizedBox(height: 4),
            Text('📊 Items imported: $itemCount'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ All your data has been restored successfully',
                style: TextStyle(fontSize: 12),
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

        await provider.clearAllData();

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
                  '💡 You can start fresh with new calculations or import previous backup data',
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
