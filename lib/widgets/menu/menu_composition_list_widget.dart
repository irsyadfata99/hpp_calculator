// lib/widgets/menu/menu_composition_list_widget.dart - FIXED SAFE VERSION

import 'package:flutter/material.dart';
import '../../services/universal_unit_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

// FIXED: Proper data model for composition items
class CompositionItemData {
  final String namaIngredient;
  final double jumlahDipakai;
  final String satuan;
  final double hargaPerSatuan;
  final double totalCost;
  final bool isValid;

  const CompositionItemData({
    required this.namaIngredient,
    required this.jumlahDipakai,
    required this.satuan,
    required this.hargaPerSatuan,
    required this.totalCost,
    required this.isValid,
  });

  // FIXED: Safe factory constructor from dynamic data
  factory CompositionItemData.fromDynamic(dynamic item) {
    try {
      String namaIngredient = '';
      double jumlahDipakai = 0.0;
      String satuan = 'unit';
      double hargaPerSatuan = 0.0;
      double totalCost = 0.0;

      // Handle Map<String, dynamic>
      if (item is Map<String, dynamic>) {
        namaIngredient = _safeGetString(item['namaIngredient']) ??
            _safeGetString(item['nama_ingredient']) ??
            'Unknown Ingredient';
        jumlahDipakai = _safeGetDouble(item['jumlahDipakai']) ??
            _safeGetDouble(item['jumlah_dipakai']) ??
            0.0;
        satuan = _safeGetString(item['satuan']) ?? 'unit';
        hargaPerSatuan = _safeGetDouble(item['hargaPerSatuan']) ??
            _safeGetDouble(item['harga_per_satuan']) ??
            0.0;
        totalCost = _safeGetDouble(item['totalCost']) ??
            _safeGetDouble(item['total_cost']) ??
            (jumlahDipakai * hargaPerSatuan);
      }
      // Handle object with properties (MenuComposition-like)
      else if (item != null) {
        try {
          // Use dynamic property access with null safety
          namaIngredient =
              item.namaIngredient?.toString() ?? 'Unknown Ingredient';
          jumlahDipakai = _parseDouble(item.jumlahDipakai) ?? 0.0;
          satuan = item.satuan?.toString() ?? 'unit';
          hargaPerSatuan = _parseDouble(item.hargaPerSatuan) ?? 0.0;

          // Try to get totalCost, calculate if not available
          totalCost =
              _parseDouble(item.totalCost) ?? (jumlahDipakai * hargaPerSatuan);
        } catch (e) {
          debugPrint('❌ Error accessing object properties: $e');
          return CompositionItemData._createInvalid();
        }
      } else {
        return CompositionItemData._createInvalid();
      }

      // Validate parsed data
      bool isValid = namaIngredient.isNotEmpty &&
          namaIngredient != 'Unknown Ingredient' &&
          jumlahDipakai > 0 &&
          hargaPerSatuan >= 0 &&
          totalCost >= 0 &&
          satuan.isNotEmpty;

      return CompositionItemData(
        namaIngredient: namaIngredient,
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
        totalCost: totalCost,
        isValid: isValid,
      );
    } catch (e) {
      debugPrint('❌ Error parsing composition item: $e');
      return CompositionItemData._createInvalid();
    }
  }

  // FIXED: Create invalid item as fallback
  factory CompositionItemData._createInvalid() {
    return const CompositionItemData(
      namaIngredient: 'Invalid Item',
      jumlahDipakai: 0.0,
      satuan: 'unit',
      hargaPerSatuan: 0.0,
      totalCost: 0.0,
      isValid: false,
    );
  }

  // FIXED: Safe string getter
  static String? _safeGetString(dynamic value) {
    if (value == null) return null;
    try {
      String str = value.toString().trim();
      return str.isEmpty ? null : str;
    } catch (e) {
      return null;
    }
  }

  // FIXED: Safe double getter with validation
  static double? _safeGetDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is double) {
        return value.isFinite ? value : null;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is num) {
        double d = value.toDouble();
        return d.isFinite ? d : null;
      }
      if (value is String) {
        String clean = value.trim();
        if (clean.isEmpty) return null;
        return double.tryParse(clean);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // FIXED: Parse double from dynamic with fallback
  static double? _parseDouble(dynamic value) {
    return _safeGetDouble(value);
  }
}

class MenuCompositionListWidget extends StatelessWidget {
  final List<dynamic> komposisiMenu;
  final Function(int) onRemoveItem;

  const MenuCompositionListWidget({
    super.key,
    required this.komposisiMenu,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: AppConstants.cardElevation,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildContent(),
              ],
            ),
          ),
        ),
        // FIXED: Only show total if there are valid items
        if (_getValidItems().isNotEmpty) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          _buildTotalCard(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    int validCount = _getValidItems().length;
    int totalCount = komposisiMenu.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MenuColors.compositionLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.list_alt,
            color: MenuColors.composition,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Menu Composition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MenuColors.composition,
            ),
          ),
        ),
        if (totalCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: validCount == totalCount
                  ? MenuColors.composition
                  : AppColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$validCount/$totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    List<CompositionItemData> validItems = _getValidItems();
    List<dynamic> invalidItems = _getInvalidItems();

    if (komposisiMenu.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Valid items
        if (validItems.isNotEmpty) ...[
          _buildValidItemsList(validItems),
        ],

        // Invalid items warning
        if (invalidItems.isNotEmpty) ...[
          if (validItems.isNotEmpty) const SizedBox(height: 12),
          _buildInvalidItemsWarning(invalidItems.length),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant, color: Colors.grey, size: 48),
          SizedBox(height: 8),
          Text(
            'No ingredients added yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add ingredients to see menu composition',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidItemsList(List<CompositionItemData> items) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildCompositionItem(
              items[index], _getOriginalIndex(items[index]));
        },
      ),
    );
  }

  Widget _buildCompositionItem(CompositionItemData item, int originalIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MenuColors.compositionLight,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: MenuColors.composition.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MenuColors.composition.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.restaurant,
              color: MenuColors.composition,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient name
                Text(
                  item.namaIngredient,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Usage details
                Text(
                  '${_formatQuantity(item.jumlahDipakai)} ${item.satuan} × ${UniversalUnitService.formatRupiah(item.hargaPerSatuan)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 2),

                // Total cost
                Text(
                  UniversalUnitService.formatRupiah(item.totalCost),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MenuColors.composition,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => onRemoveItem(originalIndex),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red[50],
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Remove ingredient',
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidItemsWarning(int invalidCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$invalidCount invalid item${invalidCount > 1 ? 's' : ''} detected',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showInvalidItemsDialog(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              'Details',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    double total = _calculateTotal();
    int validCount = _getValidItems().length;

    return Card(
      color: MenuColors.compositionLight,
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: MenuColors.composition, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Total Ingredients Cost',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MenuColors.composition,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    UniversalUnitService.formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From $validCount ingredient${validCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Helper methods with proper error handling
  List<CompositionItemData> _getValidItems() {
    List<CompositionItemData> validItems = [];

    for (var item in komposisiMenu) {
      try {
        CompositionItemData parsed = CompositionItemData.fromDynamic(item);
        if (parsed.isValid) {
          validItems.add(parsed);
        }
      } catch (e) {
        debugPrint('❌ Error parsing composition item: $e');
        // Skip invalid items
      }
    }

    return validItems;
  }

  List<dynamic> _getInvalidItems() {
    List<dynamic> invalidItems = [];

    for (var item in komposisiMenu) {
      try {
        CompositionItemData parsed = CompositionItemData.fromDynamic(item);
        if (!parsed.isValid) {
          invalidItems.add(item);
        }
      } catch (e) {
        invalidItems.add(item);
      }
    }

    return invalidItems;
  }

  int _getOriginalIndex(CompositionItemData targetItem) {
    // Find original index in komposisiMenu list
    for (int i = 0; i < komposisiMenu.length; i++) {
      try {
        CompositionItemData parsed =
            CompositionItemData.fromDynamic(komposisiMenu[i]);
        if (parsed.isValid &&
            parsed.namaIngredient == targetItem.namaIngredient &&
            parsed.jumlahDipakai == targetItem.jumlahDipakai &&
            parsed.satuan == targetItem.satuan) {
          return i;
        }
      } catch (e) {
        continue;
      }
    }
    return 0; // Fallback
  }

  double _calculateTotal() {
    try {
      List<CompositionItemData> validItems = _getValidItems();
      return validItems.fold(0.0, (sum, item) => sum + item.totalCost);
    } catch (e) {
      debugPrint('❌ Error calculating total cost: $e');
      return 0.0;
    }
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    } else {
      return quantity.toStringAsFixed(1);
    }
  }

  void _showInvalidItemsDialog() {
    // This would show a dialog with details about invalid items
    // Implementation depends on context availability
    debugPrint('📋 Invalid items dialog requested');
  }
}
