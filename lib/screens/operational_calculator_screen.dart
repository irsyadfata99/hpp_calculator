// lib/screens/operational_calculator_screen.dart (Fixed Constructor)

import 'package:flutter/material.dart';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../widgets/operational/karyawan_widget.dart';
import '../widgets/operational/operational_cost_widget.dart';
import '../widgets/operational/total_operational_result_widget.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../theme/app_colors.dart';
import '../services/operational_calculator_service.dart';

class OperationalCalculatorScreen extends StatefulWidget {
  // REMOVED: Required sharedData parameter
  const OperationalCalculatorScreen({
    super.key,
  });

  @override
  OperationalCalculatorScreenState createState() =>
      OperationalCalculatorScreenState();
}

class OperationalCalculatorScreenState
    extends State<OperationalCalculatorScreen> {
  // LOCAL STATE - temporary until full Provider integration
  List<KaryawanData> karyawan = [];
  SharedCalculationData sharedData = SharedCalculationData();

  bool isCalculating = false;
  OperationalCalculationResult? calculationResult;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _hitungOperational();
  }

  Future<void> _hitungOperational() async {
    if (!mounted) return;

    setState(() {
      isCalculating = true;
      errorMessage = null;
    });

    try {
      // Use local state instead of widget.sharedData
      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: karyawan,
        hppMurniPerPorsi: sharedData.hppMurniPerPorsi,
        estimasiPorsiPerProduksi: sharedData.estimasiPorsi,
        estimasiProduksiBulanan: sharedData.estimasiProduksiBulanan,
      );

      if (!mounted) return;

      setState(() {
        calculationResult = result;
        errorMessage = result.isValid ? null : result.errorMessage;
        isCalculating = false;
      });

      // Update local shared data
      if (result.isValid) {
        sharedData.totalOperationalCost = result.totalGajiBulanan;
        sharedData.totalHargaSetelahOperational =
            result.totalHargaSetelahOperational;
        sharedData.updateCalculatedValues();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error perhitungan operational: ${e.toString()}';
        calculationResult = null;
        isCalculating = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: AppConstants.shortAnimation,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: AppConstants.mediumAnimation,
      ),
    );
  }

  void _showWarningMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: AppConstants.mediumAnimation,
      ),
    );
  }

  Future<void> _addKaryawan(String nama, String jabatan, double gaji) async {
    // Comprehensive validation menggunakan integrated validators
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _showErrorMessage('Nama karyawan: $namaValidation');
      return;
    }

    final jabatanValidation = InputValidator.validateName(jabatan);
    if (jabatanValidation != null) {
      _showErrorMessage('Jabatan: $jabatanValidation');
      return;
    }

    final gajiValidation = InputValidator.validateSalary(gaji.toString());
    if (gajiValidation != null) {
      _showErrorMessage('Gaji: $gajiValidation');
      return;
    }

    // Business validation using constants
    if (gaji > AppConstants.maxPrice) {
      _showErrorMessage(
          'Gaji terlalu besar (maksimal ${AppFormatters.formatRupiah(AppConstants.maxPrice)})');
      return;
    }

    if (gaji < 100000) {
      _showWarningMessage(
          'Gaji di bawah standar minimum. Pastikan sudah sesuai regulasi.');
    }

    // Check for duplicate names
    bool isDuplicate =
        karyawan.any((k) => k.namaKaryawan.toLowerCase() == nama.toLowerCase());

    if (isDuplicate) {
      _showErrorMessage('Nama karyawan sudah ada. Gunakan nama yang berbeda.');
      return;
    }

    // Add karyawan to local state
    setState(() {
      karyawan = [
        ...karyawan,
        KaryawanData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          namaKaryawan: nama.trim(),
          jabatan: jabatan.trim(),
          gajiBulanan: gaji,
          createdAt: DateTime.now(),
        ),
      ];
      // Update shared data karyawan
      sharedData = sharedData.copyWith(karyawan: karyawan);
    });

    await _hitungOperational();
    _showSuccessMessage(AppConstants.successDataSaved);
  }

  Future<void> _removeKaryawan(int index) async {
    if (index < 0 || index >= karyawan.length) {
      _showErrorMessage('Index karyawan tidak valid');
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text(
            'Apakah Anda yakin ingin menghapus karyawan "${karyawan[index].namaKaryawan}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        List<KaryawanData> newList = [...karyawan];
        newList.removeAt(index);
        karyawan = newList;
        // Update shared data karyawan
        sharedData = sharedData.copyWith(karyawan: karyawan);
      });

      await _hitungOperational();
      _showSuccessMessage(AppConstants.successDataDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Operational'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (calculationResult != null && calculationResult!.isValid)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => _showAnalysisDialog(),
              tooltip: 'Analisis Efisiensi',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'reset':
                  await _resetAllData();
                  break;
                case 'efficiency':
                  _showEfficiencyAnalysis();
                  break;
                case 'projection':
                  _showProjectionAnalysis();
                  break;
              }
            },
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
      body: isCalculating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // Error Message
                  if (errorMessage != null) _buildErrorMessage(),

                  // Operational Summary Card
                  _buildOperationalSummaryCard(),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Karyawan Card - Pass local state
                  KaryawanWidget(
                    sharedData: sharedData,
                    onDataChanged: _hitungOperational,
                    onAddKaryawan: _addKaryawan,
                    onRemoveKaryawan: _removeKaryawan,
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Operational Cost Card - Pass local state
                  OperationalCostWidget(
                    sharedData: sharedData,
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Total Result Card - Pass local state
                  TotalOperationalResultWidget(
                    sharedData: sharedData,
                  ),

                  // Analysis Cards (if calculation is valid)
                  if (calculationResult != null &&
                      calculationResult!.isValid) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildEfficiencyCard(),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildProjectionCard(),
                  ],

                  // Bottom padding
                  const SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorMessage() {
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
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSummaryCard() {
    final totalKaryawan = karyawan.length;
    final totalGaji = sharedData.calculateTotalOperationalCost();
    final averageGaji = totalKaryawan > 0 ? totalGaji / totalKaryawan : 0.0;

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: AppColors.info, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                const Text('Ringkasan Operational',
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
                _buildSummaryItem('Total Gaji',
                    AppFormatters.formatRupiah(totalGaji), AppColors.success),
                _buildSummaryItem('Rata-rata',
                    AppFormatters.formatRupiah(averageGaji), AppColors.info),
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
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildEfficiencyCard() {
    if (calculationResult == null || !calculationResult!.isValid) {
      return const SizedBox.shrink();
    }

    final analysis = OperationalCalculatorService.analyzeKaryawanEfficiency(
      karyawan: karyawan,
      totalPorsiBulanan: calculationResult!.totalPorsiBulanan,
    );

    Color efficiencyColor = _getEfficiencyColor(analysis['efficiency']);

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
            _buildAnalysisRow(
                'Level Efisiensi:', analysis['efficiency'], efficiencyColor),
            _buildAnalysisRow(
                'Porsi per Karyawan:',
                '${analysis['porsiPerKaryawan'].toStringAsFixed(0)} porsi',
                AppColors.textPrimary),
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: efficiencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Text(
                analysis['recommendation'],
                style: TextStyle(fontSize: 12, color: efficiencyColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard() {
    if (calculationResult == null || !calculationResult!.isValid) {
      return const SizedBox.shrink();
    }

    final projection =
        OperationalCalculatorService.calculateOperationalProjection(
      karyawan: karyawan,
      estimasiPorsiPerProduksi: sharedData.estimasiPorsi,
      estimasiProduksiBulanan: sharedData.estimasiProduksiBulanan,
    );

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.secondary, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                const Text('Proyeksi Operasional',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _buildAnalysisRow(
                'Biaya per Hari:',
                AppFormatters.formatRupiah(projection['operationalPerHari']),
                AppColors.textPrimary),
            _buildAnalysisRow(
                'Biaya per Porsi:',
                AppFormatters.formatRupiah(projection['operationalPerPorsi']),
                AppColors.textPrimary),
            _buildAnalysisRow(
                'Total per Bulan:',
                AppFormatters.formatRupiah(projection['totalGajiBulanan']),
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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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

  Future<void> _resetAllData() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Semua Data'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua data karyawan? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      setState(() {
        karyawan = [];
        sharedData = sharedData.copyWith(
          karyawan: [],
          totalOperationalCost: 0.0,
          totalHargaSetelahOperational: sharedData.hppMurniPerPorsi,
        );
      });

      await _hitungOperational();
      _showSuccessMessage('Semua data operational telah direset');
    }
  }

  void _showAnalysisDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis Detail'),
        content: const Text('Feature analisis detail akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showEfficiencyAnalysis() {
    if (calculationResult == null || !calculationResult!.isValid) return;

    final analysis = OperationalCalculatorService.analyzeKaryawanEfficiency(
      karyawan: karyawan,
      totalPorsiBulanan: calculationResult!.totalPorsiBulanan,
    );

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
                'Porsi per Karyawan: ${analysis['porsiPerKaryawan'].toStringAsFixed(1)}'),
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

  void _showProjectionAnalysis() {
    if (calculationResult == null || !calculationResult!.isValid) return;

    final projection =
        OperationalCalculatorService.calculateOperationalProjection(
      karyawan: karyawan,
      estimasiPorsiPerProduksi: sharedData.estimasiPorsi,
      estimasiProduksiBulanan: sharedData.estimasiProduksiBulanan,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proyeksi Operasional Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Total Bulanan: ${AppFormatters.formatRupiah(projection['totalGajiBulanan'])}'),
            const SizedBox(height: 8),
            Text(
                'Per Hari: ${AppFormatters.formatRupiah(projection['operationalPerHari'])}'),
            const SizedBox(height: 8),
            Text(
                'Per Porsi: ${AppFormatters.formatRupiah(projection['operationalPerPorsi'])}'),
            const SizedBox(height: 8),
            Text(
                'Rata-rata Gaji: ${AppFormatters.formatRupiah(projection['averageGajiPerKaryawan'])}'),
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
}
