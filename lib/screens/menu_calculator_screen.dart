// lib/screens/menu_calculator_screen.dart - PHASE 1 FIX: No DataSyncController
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

class MenuCalculatorScreen extends StatelessWidget {
  const MenuCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer2<MenuProvider, HPPProvider>(
        builder: (context, menuProvider, hppProvider, child) {
          // FIXED: Check for prerequisites first
          if (hppProvider.data.variableCosts.isEmpty) {
            return _buildEmptyHPPDataState(context);
          }

          return _buildMainContent(context, menuProvider);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
                onPressed: () => _showMenuAnalysis(context, provider),
                tooltip: 'Menu Analysis',
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
                title: Text('Save Menu'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'reset_current',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Reset Current'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyHPPDataState(BuildContext context) {
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
              'Please add ingredient data in HPP Calculator first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please switch to HPP Calculator tab'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to HPP Calculator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, MenuProvider menuProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Error message
          if (menuProvider.errorMessage != null)
            _buildErrorMessage(menuProvider),

          // Menu Summary
          _buildMenuSummaryCard(menuProvider),
          const SizedBox(height: AppConstants.defaultPadding),

          // Menu Input - FIXED: Simple widget
          MenuInputWidget(
            namaMenu: menuProvider.namaMenu,
            marginPercentage: menuProvider.marginPercentage,
            onNamaMenuChanged: menuProvider.updateNamaMenu,
            onMarginChanged: menuProvider.updateMarginPercentage,
            onDataChanged: () {}, // Not needed with Provider
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Ingredient Selector - FIXED: Simple widget
          MenuIngredientSelectorWidget(
            availableIngredients: menuProvider.availableIngredients,
            onAddIngredient: menuProvider.addIngredient,
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Menu Composition - FIXED: Safe widget
          MenuCompositionListWidget(
            komposisiMenu: menuProvider.komposisiMenu,
            onRemoveItem: menuProvider.removeIngredient,
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Calculation Result - FIXED: Simple widget
          MenuCalculationResultWidget(
            namaMenu: menuProvider.namaMenu,
            calculationResult: menuProvider.lastCalculationResult,
          ),

          // Save button
          if (menuProvider.isMenuValid) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSaveMenuButton(context, menuProvider),
          ],

          const SizedBox(height: AppConstants.largePadding),
        ],
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
                Text('Menu Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Ingredients',
                    provider.ingredientCount.toString(), MenuColors.ingredient),
                _buildSummaryItem('Total Cost',
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

  Widget _buildSaveMenuButton(BuildContext context, MenuProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleSaveMenu(context, provider),
        icon: const Icon(Icons.save),
        label: const Text('Save Menu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MenuColors.result,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showMenuAnalysis(BuildContext context, MenuProvider provider) {
    final analysis = provider.getMenuAnalysis();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analysis: ${provider.namaMenu}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.isNotEmpty && analysis['isAvailable'] == true) ...[
              Text('Category: ${analysis['kategori'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Selling Price: ${provider.formattedHargaJual}'),
              const SizedBox(height: 8),
              Text('Profit: ${provider.formattedProfit}'),
              const SizedBox(height: 8),
              Text('Margin: ${provider.marginPercentage.toStringAsFixed(1)}%'),
            ] else ...[
              const Text('Analysis not available'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    try {
      switch (action) {
        case 'save':
          await _handleSaveMenu(context, menuProvider);
          break;
        case 'reset_current':
          await _handleResetCurrent(context, menuProvider);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling menu action: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

    try {
      await provider.saveCurrentMenu();

      if (context.mounted && provider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Menu saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving menu: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleResetCurrent(
      BuildContext context, MenuProvider provider) async {
    final shouldReset = await ConfirmationDialog.show(
      context,
      title: 'Reset Current Menu',
      message: 'Are you sure you want to reset the current menu?',
      confirmText: 'Reset',
      cancelText: 'Cancel',
    );

    if (shouldReset == true) {
      provider.resetCurrentMenu();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Current menu reset'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}
