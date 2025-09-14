// lib/screens/menu_calculator_screen.dart - FIXED VERSION: PUBLIC METHOD CALLS

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

    // FIXED: Safe provider communication with validation and public method calls
    try {
      if (hppProvider.data.variableCosts.isNotEmpty) {
        menuProvider.updateSharedData(hppProvider.data);
      } else {
        print('⚠️ HPP data is empty during setup');
      }
    } catch (e) {
      print('❌ Error setting up provider communication: $e');
      // FIXED: Use public method instead of private _setError
      menuProvider.setError(
          'Unable to load ingredient data. Please check HPP Calculator first.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer2<MenuProvider, HPPProvider>(
        builder: (context, menuProvider, hppProvider, child) {
          // FIXED: Critical error boundary - handle TypeError and navigation issues
          if (menuProvider.errorMessage?.contains('TypeError') == true ||
              hppProvider.errorMessage?.contains('TypeError') == true ||
              menuProvider.errorMessage
                      ?.contains('Error loading ingredient data') ==
                  true) {
            return _buildCriticalErrorState(menuProvider, hppProvider);
          }

          // FIXED: Safe data flow - prevent crashes during provider communication
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (hppProvider.data.variableCosts.isNotEmpty) {
                menuProvider.updateSharedData(hppProvider.data);
              } else {
                print('⚠️ HPP data is empty, skipping menu provider update');
              }
            } catch (e) {
              print('❌ Error updating shared data: $e');
              // FIXED: Use public method instead of private _setError
              menuProvider.setError(
                  'Unable to load ingredient data. Please check HPP Calculator first.');
            }
          });

          // FIXED: Pre-flight check for required data
          if (hppProvider.data.variableCosts.isEmpty) {
            return _buildEmptyDataState();
          }

          if (menuProvider.isLoading) {
            return const LoadingWidget(message: 'Menghitung menu...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Error Message with enhanced handling
                if (menuProvider.errorMessage != null)
                  _buildErrorMessage(menuProvider),

                // Menu Summary Card
                _buildMenuSummaryCard(menuProvider),

                const SizedBox(height: AppConstants.defaultPadding),

                // Menu Input Widget
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

                // FIXED: Safe Ingredient Selector Widget with validation
                Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    // FIXED: Validate available ingredients before rendering
                    if (provider.availableIngredients.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.warning_amber,
                                  size: 48, color: Colors.orange),
                              const SizedBox(height: 16),
                              const Text(
                                'No ingredients available',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please add ingredient data in HPP Calculator first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back to HPP'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

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

  // FIXED: Enhanced AppBar with explicit back button and error clearing
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Menu Calculator'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      // FIXED: Explicit leading button with error clearing
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Clear any errors before navigation to prevent state issues
          try {
            final menuProvider =
                Provider.of<MenuProvider>(context, listen: false);
            final hppProvider =
                Provider.of<HPPProvider>(context, listen: false);

            // FIXED: Use public methods instead of private methods
            menuProvider.clearError();
            hppProvider.clearError();

            Navigator.of(context).pop();
          } catch (e) {
            print('❌ Error during navigation: $e');
            Navigator.of(context)
                .pop(); // Force navigation even if error clearing fails
          }
        },
        tooltip: 'Back to previous screen',
      ),
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

  // FIXED: Add critical error state handler
  Widget _buildCriticalErrorState(
      MenuProvider menuProvider, HPPProvider hppProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Menu Calculator Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${menuProvider.errorMessage ?? hppProvider.errorMessage ?? "Unknown error"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // FIXED: Use public methods instead of private methods
                    menuProvider.clearError();
                    hppProvider.clearError();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to HPP'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // FIXED: Use public methods instead of private methods
                    menuProvider.clearError();
                    hppProvider.clearError();
                    menuProvider.resetCurrentMenu();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset & Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Add empty data state handler
  Widget _buildEmptyDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'No Ingredient Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please add ingredient data in HPP Calculator first.\n\nMenu Calculator needs ingredient data to calculate menu costs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to HPP Calculator'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
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
