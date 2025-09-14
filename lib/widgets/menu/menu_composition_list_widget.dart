// lib/widgets/menu/menu_composition_list_widget.dart - CRITICAL FIX
import 'package:flutter/material.dart';
import '../../services/universal_unit_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

// FIXED: Simplified & Type-Safe composition item
class SafeCompositionItem {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalCost;

  const SafeCompositionItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalCost,
  });

  // FIXED: Ultra-safe factory constructor
  factory SafeCompositionItem.fromDynamic(dynamic item) {
    try {
      if (item == null) return SafeCompositionItem._invalid();

      // Handle MenuComposition objects (has properties)
      if (item.runtimeType.toString().contains('MenuComposition')) {
        return SafeCompositionItem(
          name: _getProperty(item, 'namaIngredient') ?? 'Unknown',
          quantity: _parseDouble(_getProperty(item, 'jumlahDipakai')) ?? 0.0,
          unit: _getProperty(item, 'satuan') ?? 'unit',
          unitPrice: _parseDouble(_getProperty(item, 'hargaPerSatuan')) ?? 0.0,
          totalCost: _parseDouble(_getProperty(item, 'totalCost')) ?? 0.0,
        );
      }

      // Handle Map objects
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        return SafeCompositionItem(
          name: _parseString(map['namaIngredient'] ?? map['nama_ingredient']) ??
              'Unknown',
          quantity:
              _parseDouble(map['jumlahDipakai'] ?? map['jumlah_dipakai']) ??
                  0.0,
          unit: _parseString(map['satuan']) ?? 'unit',
          unitPrice:
              _parseDouble(map['hargaPerSatuan'] ?? map['harga_per_satuan']) ??
                  0.0,
          totalCost: _parseDouble(map['totalCost'] ?? map['total_cost']) ?? 0.0,
        );
      }

      return SafeCompositionItem._invalid();
    } catch (e) {
      debugPrint('⚠️ Safe parsing failed: $e');
      return SafeCompositionItem._invalid();
    }
  }

  factory SafeCompositionItem._invalid() {
    return const SafeCompositionItem(
      name: 'Invalid Item',
      quantity: 0.0,
      unit: 'unit',
      unitPrice: 0.0,
      totalCost: 0.0,
    );
  }

  bool get isValid =>
      name != 'Invalid Item' &&
      name != 'Unknown' &&
      name.isNotEmpty &&
      quantity > 0 &&
      totalCost >= 0;

  // FIXED: Safe property access using try-catch
  static dynamic _getProperty(dynamic object, String propertyName) {
    try {
      switch (propertyName) {
        case 'namaIngredient':
          return object.namaIngredient;
        case 'jumlahDipakai':
          return object.jumlahDipakai;
        case 'satuan':
          return object.satuan;
        case 'hargaPerSatuan':
          return object.hargaPerSatuan;
        case 'totalCost':
          return object.totalCost;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    try {
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    } catch (e) {
      return null;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is double && value.isFinite) return value;
      if (value is int) return value.toDouble();
      if (value is num) {
        final d = value.toDouble();
        return d.isFinite ? d : null;
      }
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isEmpty) return null;
        final parsed = double.tryParse(cleaned);
        return (parsed?.isFinite == true) ? parsed : null;
      }
      return null;
    } catch (e) {
      return null;
    }
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

  // FIXED: Safe list processing with error isolation
  List<SafeCompositionItem> get _safeItems {
    final List<SafeCompositionItem> items = [];

    for (int i = 0; i < komposisiMenu.length; i++) {
      try {
        final item = SafeCompositionItem.fromDynamic(komposisiMenu[i]);
        if (item.isValid) {
          items.add(item);
        }
      } catch (e) {
        debugPrint('⚠️ Skipping invalid item at index $i: $e');
        // Continue processing other items
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final safeItems = _safeItems;

    return Column(
      children: [
        Card(
          elevation: AppConstants.cardElevation,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(safeItems.length),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildContent(safeItems),
              ],
            ),
          ),
        ),
        if (safeItems.isNotEmpty) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          _buildTotalCard(safeItems),
        ],
      ],
    );
  }

  Widget _buildHeader(int validCount) {
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
        if (komposisiMenu.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: validCount == komposisiMenu.length
                  ? MenuColors.composition
                  : AppColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$validCount/${komposisiMenu.length}',
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

  Widget _buildContent(List<SafeCompositionItem> items) {
    if (komposisiMenu.isEmpty) {
      return _buildEmptyState();
    }

    if (items.isEmpty) {
      return _buildInvalidDataState();
    }

    return _buildItemsList(items);
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
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidDataState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Invalid ingredient data detected',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${komposisiMenu.length} item(s) could not be processed',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<SafeCompositionItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final originalIndex = _findOriginalIndex(item);
        return _buildCompositionItem(item, originalIndex);
      },
    );
  }

  Widget _buildCompositionItem(SafeCompositionItem item, int originalIndex) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatQuantity(item.quantity)} ${item.unit} × ${UniversalUnitService.formatRupiah(item.unitPrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
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

  Widget _buildTotalCard(List<SafeCompositionItem> items) {
    final total = items.fold(0.0, (sum, item) => sum + item.totalCost);

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
                    'From ${items.length} ingredient${items.length > 1 ? 's' : ''}',
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

  // FIXED: Safe original index finder
  int _findOriginalIndex(SafeCompositionItem targetItem) {
    for (int i = 0; i < komposisiMenu.length; i++) {
      try {
        final item = SafeCompositionItem.fromDynamic(komposisiMenu[i]);
        if (item.isValid &&
            item.name == targetItem.name &&
            (item.quantity - targetItem.quantity).abs() < 0.001 &&
            item.unit == targetItem.unit) {
          return i;
        }
      } catch (e) {
        continue; // Skip problematic items
      }
    }
    return 0; // Safe fallback
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    } else {
      return quantity.toStringAsFixed(1);
    }
  }
}
