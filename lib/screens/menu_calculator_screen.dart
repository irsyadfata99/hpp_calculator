// lib/screens/menu_calculator_screen.dart - FIXED FOR SYNC CONTROLLER
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
import '../main.dart'; // For DataSyncController

class MenuCalculatorScreen extends StatefulWidget {
  final DataSyncController syncController;

  const MenuCalculatorScreen({
    super.key,
    required this.syncController,
  });

  @override
  MenuCalculatorScreenState createState() => MenuCalculatorScreenState();
}

class MenuCalculatorScreenState extends State<MenuCalculatorScreen> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() async {
    try {
      // Wait for next frame to ensure providers are ready
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      // FIXED: Simple one-time sync - no loops
      if (hppProvider.data.variableCosts.isNotEmpty) {
        menuProvider.updateSharedData(hppProvider.data);
        debugPrint('✅ Menu screen initialized with HPP data');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Menu screen initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const LoadingWidget(message: 'Loading menu calculator...'),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildErrorState(_initError!),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, child) {
          // FIXED: Simple error handling
          if (menuProvider.errorMessage?.contains('TypeError') == true) {
            return _buildErrorState('Menu calculation error');
          }

          return _buildMainContent(menuProvider);
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
                tooltip: 'Menu Analysis',
              );
            }
            return const SizedBox.shrink();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
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

  Widget _buildErrorState(String error) {
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                  _initError = null;
                });
                _initializeScreen();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(MenuProvider menuProvider) {
    // FIXED: Check for prerequisites first
    final hppProvider = Provider.of<HPPProvider>(context, listen: false);

    if (hppProvider.data.variableCosts.isEmpty) {
      return _buildEmptyHPPDataState();
    }

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

          // Menu Input - FIXED: Safe widget wrapper
          _buildSafeWidget(
            () => MenuInputWidget(
              namaMenu: menuProvider.namaMenu,
              marginPercentage: menuProvider.marginPercentage,
              onNamaMenuChanged: menuProvider.updateNamaMenu,
              onMarginChanged: menuProvider.updateMarginPercentage,
              onDataChanged: () {}, // Not needed with Provider
            ),
            'Menu Input',
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Ingredient Selector - FIXED: Safe widget wrapper
          _buildSafeWidget(
            () => MenuIngredientSelectorWidget(
              availableIngredients: menuProvider.availableIngredients,
              onAddIngredient: menuProvider.addIngredient,
            ),
            'Ingredient Selector',
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Menu Composition - FIXED: Safe widget wrapper
          _buildSafeWidget(
            () => MenuCompositionListWidget(
              komposisiMenu: menuProvider.komposisiMenu,
              onRemoveItem: menuProvider.removeIngredient,
            ),
            'Menu Composition',
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Calculation Result - FIXED: Safe widget wrapper
          _buildSafeWidget(
            () => MenuCalculationResultWidget(
              namaMenu: menuProvider.namaMenu,
              calculationResult: menuProvider.lastCalculationResult,
            ),
            'Menu Result',
          ),

          // Save button
          if (menuProvider.isMenuValid) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSaveMenuButton(menuProvider),
          ],

          const SizedBox(height: AppConstants.largePadding),
        ],
      ),
    );
  }

  // FIXED: Safe widget wrapper to prevent crashes
  Widget _buildSafeWidget(Widget Function() builder, String widgetName) {
    try {
      return builder();
    } catch (e) {
      debugPrint('❌ Error rendering $widgetName: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text('$widgetName Error',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Widget failed to render: ${e.toString()}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {}), // Trigger rebuild
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEmptyHPPDataState() {
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

  Widget _buildSaveMenuButton(MenuProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleSaveMenu(provider),
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

  void _showMenuAnalysis(MenuProvider provider) {
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

  void _handleMenuAction(String action) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    try {
      switch (action) {
        case 'save':
          await _handleSaveMenu(menuProvider);
          break;
        case 'reset_current':
          await _handleResetCurrent(menuProvider);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling menu action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveMenu(MenuProvider provider) async {
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

  Future<void> _handleResetCurrent(MenuProvider provider) async {
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
