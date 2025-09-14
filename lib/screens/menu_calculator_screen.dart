// lib/screens/menu_calculator_screen.dart - FIXED VERSION: Import Issue

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/hpp_provider.dart';
import '../widgets/menu/menu_input_widget.dart';
import '../widgets/menu/menu_ingredient_selector_widget.dart';
// FIXED: Add import for MenuCompositionListWidget
import '../widgets/menu/menu_composition_list_widget.dart'; // Add this import
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
  // FIXED: Add flag to prevent infinite provider updates
  bool _isUpdatingProviders = false;

  @override
  void initState() {
    super.initState();
    // FIXED: Delay provider setup to next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupProviderCommunicationSafe();
      }
    });
  }

  // FIXED: Safe provider communication without infinite loops
  void _setupProviderCommunicationSafe() {
    if (_isUpdatingProviders) return;

    try {
      _isUpdatingProviders = true;

      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      // Only sync if HPP has valid data
      if (hppProvider.data.variableCosts.isNotEmpty) {
        debugPrint('🔄 Syncing HPP data to Menu provider');
        menuProvider.updateSharedData(hppProvider.data);
      } else {
        debugPrint('⚠️ HPP data is empty, skipping sync');
      }
    } catch (e) {
      debugPrint('❌ Error in provider communication: $e');
      // Don't throw, just log
    } finally {
      _isUpdatingProviders = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      // FIXED: Use Consumer2 with proper error boundaries
      body: Consumer2<MenuProvider, HPPProvider>(
        builder: (context, menuProvider, hppProvider, child) {
          // FIXED: Handle error states early to prevent cascading errors
          if (menuProvider.errorMessage?.contains('TypeError') == true) {
            return _buildErrorState('Menu calculation error',
                menuProvider.errorMessage ?? 'Unknown error');
          }

          if (hppProvider.errorMessage?.contains('TypeError') == true) {
            return _buildErrorState(
                'HPP data error', hppProvider.errorMessage ?? 'Unknown error');
          }

          // FIXED: Safe provider sync without listeners (prevents infinite loops)
          if (!_isUpdatingProviders &&
              hppProvider.data.variableCosts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _setupProviderCommunicationSafe();
              }
            });
          }

          // FIXED: Check for empty HPP data
          if (hppProvider.data.variableCosts.isEmpty) {
            return _buildEmptyHPPDataState();
          }

          // FIXED: Loading state
          if (menuProvider.isLoading) {
            return const LoadingWidget(message: 'Loading menu data...');
          }

          // FIXED: Main content with proper error boundaries
          return _buildMainContent(menuProvider, hppProvider);
        },
      ),
    );
  }

  // FIXED: Simplified AppBar without complex navigation logic
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

  // FIXED: Error state widget
  Widget _buildErrorState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final menuProvider =
                    Provider.of<MenuProvider>(context, listen: false);
                menuProvider.clearError();
                menuProvider.resetCurrentMenu();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset & Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Empty HPP data state
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
                // Navigate to HPP tab
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to HPP Calculator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Main content with proper layout constraints
  Widget _buildMainContent(MenuProvider menuProvider, HPPProvider hppProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // FIXED: Error message with better error handling
          if (menuProvider.errorMessage != null)
            _buildErrorMessage(menuProvider),

          // Menu Summary Card
          _buildMenuSummaryCard(menuProvider),

          const SizedBox(height: AppConstants.defaultPadding),

          // FIXED: Menu Input Widget with error boundary
          _buildMenuInputWidget(menuProvider),

          const SizedBox(height: AppConstants.defaultPadding),

          // FIXED: Ingredient Selector with validation
          _buildIngredientSelectorWidget(menuProvider),

          const SizedBox(height: AppConstants.defaultPadding),

          // Menu Composition List Widget
          _buildMenuCompositionWidget(menuProvider),

          const SizedBox(height: AppConstants.defaultPadding),

          // Menu Calculation Result Widget
          _buildMenuResultWidget(menuProvider),

          // Save Menu Button (if valid)
          if (menuProvider.isMenuValid) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSaveMenuButton(menuProvider),
          ],

          // Bottom padding
          const SizedBox(height: AppConstants.largePadding),
        ],
      ),
    );
  }

  // FIXED: Individual widget builders with error boundaries

  Widget _buildMenuInputWidget(MenuProvider menuProvider) {
    try {
      return MenuInputWidget(
        namaMenu: menuProvider.namaMenu,
        marginPercentage: menuProvider.marginPercentage,
        onNamaMenuChanged: (nama) {
          menuProvider.updateNamaMenu(nama);
        },
        onMarginChanged: (margin) {
          menuProvider.updateMarginPercentage(margin);
        },
        onDataChanged: () {
          // Data changes handled by provider
        },
      );
    } catch (e) {
      debugPrint('❌ Error in menu input widget: $e');
      return _buildWidgetErrorCard('Menu Input Error');
    }
  }

  Widget _buildIngredientSelectorWidget(MenuProvider menuProvider) {
    try {
      // FIXED: Validate available ingredients before rendering
      final availableIngredients = menuProvider.availableIngredients;

      if (availableIngredients.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'No ingredients available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please add ingredient data in HPP Calculator first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      return MenuIngredientSelectorWidget(
        availableIngredients: availableIngredients,
        onAddIngredient: (namaIngredient, jumlah, satuan, hargaPerSatuan) {
          menuProvider.addIngredient(
              namaIngredient, jumlah, satuan, hargaPerSatuan);
        },
      );
    } catch (e) {
      debugPrint('❌ Error in ingredient selector widget: $e');
      return _buildWidgetErrorCard('Ingredient Selector Error');
    }
  }

  // FIXED: Proper widget instantiation with 'const' constructor call
  Widget _buildMenuCompositionWidget(MenuProvider menuProvider) {
    try {
      return MenuCompositionListWidget(
        komposisiMenu: menuProvider.komposisiMenu,
        onRemoveItem: (index) {
          menuProvider.removeIngredient(index);
        },
      );
    } catch (e) {
      debugPrint('❌ Error in menu composition widget: $e');
      return _buildWidgetErrorCard('Menu Composition Error');
    }
  }

  Widget _buildMenuResultWidget(MenuProvider menuProvider) {
    try {
      return MenuCalculationResultWidget(
        namaMenu: menuProvider.namaMenu,
        calculationResult: menuProvider.lastCalculationResult,
      );
    } catch (e) {
      debugPrint('❌ Error in menu result widget: $e');
      return _buildWidgetErrorCard('Menu Result Error');
    }
  }

  // FIXED: Error card for individual widget errors
  Widget _buildWidgetErrorCard(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Widget failed to render',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        onPressed: () async {
          try {
            await provider.saveCurrentMenu();
            if (mounted && provider.errorMessage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Menu saved successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ Error saving menu: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error saving menu: ${e.toString()}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
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
          content: Text('✅ Menu saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
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
