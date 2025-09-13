// lib/screens/menu_calculator_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/hpp_provider.dart';
import '../widgets/menu/menu_input_widget.dart';
import '../widgets/menu/menu_ingredient_selector_widget.dart';
import '../widgets/menu/menu_composition_list_widget.dart';
import '../widgets/menu/menu_calculation_result_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/error_dialog.dart';
import '../utils/constants.dart';
import '../theme/app_colors.dart';

class MenuCalculatorScreen extends StatefulWidget {
  const MenuCalculatorScreen({super.key});

  @override
  MenuCalculatorScreenState createState() => MenuCalculatorScreenState();
}

class MenuCalculatorScreenState extends State<MenuCalculatorScreen> {
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
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    // Update menu provider with current HPP data
    menuProvider.updateSharedData(hppProvider.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer2<MenuProvider, HPPProvider>(
        builder: (context, menuProvider, hppProvider, child) {
          // Update shared data when HPP changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            menuProvider.updateSharedData(hppProvider.data);
          });

          if (menuProvider.isLoading) {
            return const LoadingWidget(message: 'Menghitung menu...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Error Message
                if (menuProvider.errorMessage != null)
                  _buildErrorMessage(menuProvider),

                // Menu Summary Card
                _buildMenuSummaryCard(menuProvider),

                const SizedBox(height: AppConstants.defaultPadding),

                // Menu Input Widget with Provider
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    return MenuInputWidget(
                      namaMenu: provider.namaMenu,
                      marginPercentage: provider.marginPercentage,
                      onNamaMenuChanged: (nama) {
                        provider.updateNamaMenu(nama);
                      },
                      onMarginChanged: (margin) {
                        provider.updateMarginPercentage(margin);
                      },
                      onDataChanged: () {
                        // Data changes are handled automatically by provider
                      },
                    );
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Ingredient Selector Widget
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    return MenuIngredientSelectorWidget(
                      availableIngredients: provider.availableIngredients,
                      onAddIngredient:
                          (namaIngredient, jumlah, satuan, hargaPerSatuan) {
                        provider.addIngredient(
                            namaIngredient, jumlah, satuan, hargaPerSatuan);
                      },
                    );
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Menu Composition List Widget
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    return MenuCompositionListWidget(
                      komposisiMenu: provider.komposisiMenu,
                      onRemoveItem: (index) {
                        provider.removeIngredient(index);
                      },
                    );
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Menu Calculation Result Widget
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    return MenuCalculationResultWidget(
                      namaMenu: provider.namaMenu,
                      calculationResult: provider.lastCalculationResult,
                    );
                  },
                ),

                // Save Menu Button (if menu is valid)
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    if (provider.isMenuValid) {
                      return Column(
                        children: [
                          const SizedBox(height: AppConstants.defaultPadding),
                          _buildSaveMenuButton(provider),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Menu History Section
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    if (provider.hasMenuHistory) {
                      return Column(
                        children: [
                          const SizedBox(height: AppConstants.defaultPadding),
                          _buildMenuHistoryCard(provider),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Analysis Cards (if calculation is valid)
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    if (provider.lastCalculationResult?.isValid == true) {
                      return Column(
                        children: [
                          const SizedBox(height: AppConstants.defaultPadding),
                          _buildMenuAnalysisCard(provider),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

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
      title: const Text('Menu Calculator'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      actions: [
        Consumer<MenuProvider>(
          builder: (context, provider, child) {
            if (provider.lastCalculationResult?.isValid == true) {
              return IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showMenuAnalysis(provider),
                tooltip: 'Analisis Menu',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'save',
              child: ListTile(
                leading: Icon(Icons.save),
                title: Text('Simpan Menu'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Riwayat Menu'),
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
              value: 'reset_current',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Reset Menu Saat Ini'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'reset_all',
              child: ListTile(
                leading: Icon(Icons.delete_sweep),
                title: Text('Reset Semua'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(MenuProvider provider) {
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

  Widget _buildMenuSummaryCard(MenuProvider provider) {
    return Card(
      elevation: AppConstants
          .cardElevation, // FIXED: menggunakan AppConstants.cardElevation
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize, color: AppColors.info, size: 20),
                SizedBox(width: AppConstants.smallPadding),
                Text('Ringkasan Menu',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Bahan', provider.ingredientCount.toString(),
                    MenuColors.ingredient),
                _buildSummaryItem('Total Bahan',
                    provider.formattedTotalBahanBaku, MenuColors.composition),
                _buildSummaryItem(
                    'Status',
                    provider.isMenuValid ? 'Valid' : 'Invalid',
                    provider.isMenuValid ? AppColors.success : AppColors.error),
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

  Widget _buildSaveMenuButton(MenuProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await provider.saveCurrentMenu();
          if (context.mounted && provider.errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Menu berhasil disimpan!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Simpan Menu ke Riwayat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MenuColors.result,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMenuHistoryCard(MenuProvider provider) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history,
                    color: MenuColors.composition, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                const Text('Riwayat Menu',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${provider.historyCount} menu',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.menuHistory.length,
                itemBuilder: (context, index) {
                  final menu = provider.menuHistory[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: Card(
                      child: InkWell(
                        onTap: () => provider.loadMenuFromHistory(index),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menu.namaMenu,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${menu.komposisi.length} bahan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${provider.formattedTotalBahanBaku}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: MenuColors.composition,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    onPressed: () =>
                                        _confirmDeleteHistory(provider, index),
                                    color: AppColors.error,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuAnalysisCard(MenuProvider provider) {
    final analysis = provider.getMenuAnalysis();

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: MenuColors.composition, size: 20),
                SizedBox(width: AppConstants.smallPadding),
                Text('Analisis Menu',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            if (analysis.isNotEmpty) ...[
              _buildAnalysisRow('Kategori:', analysis['kategori'] ?? 'N/A',
                  MenuColors.result),
              const SizedBox(height: 4),
              _buildAnalysisRow('Harga Jual:', provider.formattedHargaJual,
                  AppColors.success),
              const SizedBox(height: 4),
              _buildAnalysisRow(
                  'Profit:', provider.formattedProfit, MenuColors.ingredient),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MenuColors.compositionLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis['rekomendasi'] ?? 'Tidak ada rekomendasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: MenuColors.composition,
                  ),
                ),
              ),
            ] else ...[
              const Text('Analisis tidak tersedia',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    switch (action) {
      case 'save':
        await _handleSaveMenu(context, menuProvider);
        break;
      case 'history':
        _showMenuHistory(menuProvider);
        break;
      case 'export':
        await _handleExport(context, menuProvider);
        break;
      case 'import':
        await _handleImport(context, menuProvider);
        break;
      case 'reset_current':
        await _handleResetCurrent(context, menuProvider);
        break;
      case 'reset_all':
        await _handleResetAll(context, menuProvider);
        break;
    }
  }

  Future<void> _handleSaveMenu(
      BuildContext context, MenuProvider provider) async {
    final validation = provider.validateCurrentMenu();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await provider.saveCurrentMenu();

    if (context.mounted && provider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Menu berhasil disimpan!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showMenuHistory(MenuProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Riwayat Menu'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: provider.hasMenuHistory
              ? ListView.builder(
                  itemCount: provider.menuHistory.length,
                  itemBuilder: (context, index) {
                    final menu = provider.menuHistory[index];
                    return ListTile(
                      title: Text(menu.namaMenu),
                      subtitle: Text('${menu.komposisi.length} bahan'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDeleteHistory(provider, index),
                      ),
                      onTap: () {
                        provider.loadMenuFromHistory(index);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                )
              : const Center(
                  child: Text('Belum ada riwayat menu'),
                ),
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

  void _showMenuAnalysis(MenuProvider provider) {
    final analysis = provider.getMenuAnalysis();
    // FIXED: Removed unused 'detailedAnalysis' variable

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analisis ${provider.namaMenu}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.isNotEmpty) ...[
              Text('Kategori: ${analysis['kategori']}'),
              const SizedBox(height: 8),
              Text('Harga Jual: ${provider.formattedHargaJual}'),
              const SizedBox(height: 8),
              Text('Profit: ${provider.formattedProfit}'),
              const SizedBox(height: 8),
              Text('Margin: ${provider.marginPercentage.toStringAsFixed(1)}%'),
            ] else ...[
              const Text('Analisis tidak tersedia'),
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

  Future<void> _confirmDeleteHistory(MenuProvider provider, int index) async {
    final shouldDelete = await ConfirmationDialog.show(
      context,
      title: 'Hapus Menu',
      message:
          'Apakah Anda yakin ingin menghapus menu "${provider.menuHistory[index].namaMenu}" dari riwayat?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );

    if (shouldDelete == true) {
      await provider.deleteMenuFromHistory(index);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu telah dihapus dari riwayat'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _handleExport(
      BuildContext context, MenuProvider provider) async {
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

      final result = await provider.exportMenuHistory();

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Menu data exported successfully!'),
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
      BuildContext context, MenuProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _handleResetCurrent(
      BuildContext context, MenuProvider provider) async {
    final shouldReset = await ConfirmationDialog.show(
      context,
      title: 'Reset Menu Saat Ini',
      message: 'Apakah Anda yakin ingin menghapus menu yang sedang dibuat?',
      confirmText: 'Reset',
      cancelText: 'Batal',
    );

    if (shouldReset == true) {
      provider.resetCurrentMenu();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Menu saat ini telah direset'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _handleResetAll(
      BuildContext context, MenuProvider provider) async {
    final shouldReset = await ConfirmationDialog.show(
      context,
      title: 'Reset Semua Data Menu',
      message:
          'Apakah Anda yakin ingin menghapus semua data menu?\n\nTermasuk:\n• Menu yang sedang dibuat\n• Semua riwayat menu\n\nTindakan ini tidak dapat dibatalkan.',
      confirmText: 'RESET SEMUA',
      cancelText: 'Batal',
    );

    if (shouldReset == true) {
      provider.resetAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Semua data menu telah dihapus'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
