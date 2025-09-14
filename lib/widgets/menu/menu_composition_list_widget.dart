// lib/widgets/menu/menu_composition_list_widget.dart - Separate Widget File

import 'package:flutter/material.dart';
import '../../services/universal_unit_service.dart';

class MenuCompositionListWidget extends StatelessWidget {
  final List<dynamic> komposisiMenu; // Accept dynamic to handle different types
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (komposisiMenu.isEmpty)
                  _buildEmptyState()
                else
                  _buildCompositionList(),
              ],
            ),
          ),
        ),
        if (komposisiMenu.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTotalCard(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.list_alt,
            color: Colors.purple[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Current Composition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
        if (komposisiMenu.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${komposisiMenu.length}',
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.restaurant, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'No ingredients added yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: List with proper constraints
  Widget _buildCompositionList() {
    return Container(
      constraints:
          const BoxConstraints(maxHeight: 400), // Prevent infinite height
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: komposisiMenu.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildCompositionItem(komposisiMenu[index], index);
        },
      ),
    );
  }

  Widget _buildCompositionItem(dynamic item, int index) {
    try {
      // FIXED: Safe property access with fallbacks
      String namaIngredient =
          _getItemProperty(item, 'namaIngredient') ?? 'Unknown';
      double jumlahDipakai = _getNumericProperty(item, 'jumlahDipakai') ?? 0.0;
      String satuan = _getItemProperty(item, 'satuan') ?? 'unit';
      double hargaPerSatuan =
          _getNumericProperty(item, 'hargaPerSatuan') ?? 0.0;
      double totalCost = _getNumericProperty(item, 'totalCost') ??
          (jumlahDipakai * hargaPerSatuan);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.purple[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaIngredient,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jumlahDipakai $satuan × ${UniversalUnitService.formatRupiah(hargaPerSatuan)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    UniversalUnitService.formatRupiah(totalCost),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onRemoveItem(index),
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error rendering composition item: $e');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Text('Error rendering item'),
      );
    }
  }

  Widget _buildTotalCard() {
    double total = _calculateTotal();

    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.purple[700], size: 20),
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
                color: Colors.purple[600],
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
                    'From ${komposisiMenu.length} ingredients',
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

  // FIXED: Safe property getters
  String? _getItemProperty(dynamic item, String property) {
    try {
      if (item is Map<String, dynamic>) {
        return item[property]?.toString();
      }
      // Handle object properties using reflection-like access
      switch (property) {
        case 'namaIngredient':
          return item?.namaIngredient?.toString();
        case 'satuan':
          return item?.satuan?.toString();
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  double? _getNumericProperty(dynamic item, String property) {
    try {
      if (item is Map<String, dynamic>) {
        var value = item[property];
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }
      // Handle object properties
      switch (property) {
        case 'jumlahDipakai':
          var value = item?.jumlahDipakai;
          return value is num ? value.toDouble() : null;
        case 'hargaPerSatuan':
          var value = item?.hargaPerSatuan;
          return value is num ? value.toDouble() : null;
        case 'totalCost':
          var value = item?.totalCost;
          return value is num ? value.toDouble() : null;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  double _calculateTotal() {
    try {
      return komposisiMenu.fold(0.0, (sum, item) {
        double? cost = _getNumericProperty(item, 'totalCost');
        if (cost == null) {
          // Calculate from jumlah * harga if totalCost not available
          double? jumlah = _getNumericProperty(item, 'jumlahDipakai');
          double? harga = _getNumericProperty(item, 'hargaPerSatuan');
          if (jumlah != null && harga != null) {
            cost = jumlah * harga;
          } else {
            cost = 0.0;
          }
        }
        return sum + cost;
      });
    } catch (e) {
      debugPrint('❌ Error calculating total: $e');
      return 0.0;
    }
  }
}
