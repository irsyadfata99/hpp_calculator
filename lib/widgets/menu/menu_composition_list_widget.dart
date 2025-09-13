// File: lib/widgets/menu_composition_list_widget.dart

import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../services/menu_calculator_service.dart';

class MenuCompositionListWidget extends StatelessWidget {
  final List<MenuComposition> komposisiMenu;
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
        // Card untuk List Komposisi
        _buildCompositionListCard(),

        const SizedBox(height: 16),

        // Card untuk Total Bahan Baku (terpisah)
        if (komposisiMenu.isNotEmpty) _buildTotalBahanBakuCard(),
      ],
    );
  }

  Widget _buildCompositionListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // List Komposisi atau Empty State
            if (komposisiMenu.isEmpty)
              _buildEmptyState()
            else
              _buildCompositionList(),
          ],
        ),
      ),
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
            'Komposisi Saat Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
        // Badge jumlah item
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
              'Belum ada bahan yang ditambahkan',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gunakan form di atas untuk menambah bahan',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: komposisiMenu.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildCompositionItem(komposisiMenu[index], index);
      },
    );
  }

  Widget _buildCompositionItem(MenuComposition item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          // Icon Ingredient
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getIngredientIcon(item.namaIngredient),
              color: Colors.purple[700],
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Info Ingredient
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaIngredient,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.jumlahDipakai} ${item.satuan}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '× ${MenuCalculatorService.formatRupiah(item.hargaPerSatuan)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  MenuCalculatorService.formatRupiah(item.totalCost),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),

          // Delete Button
          IconButton(
            onPressed: () => onRemoveItem(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red[50],
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBahanBakuCard() {
    double total = komposisiMenu.fold(0.0, (sum, item) => sum + item.totalCost);

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
                  'Total Bahan Baku',
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
                    MenuCalculatorService.formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dari ${komposisiMenu.length} bahan',
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

  IconData _getIngredientIcon(String namaIngredient) {
    String nama = namaIngredient.toLowerCase();

    if (nama.contains('beras') || nama.contains('nasi')) {
      return Icons.rice_bowl;
    } else if (nama.contains('ayam') || nama.contains('daging')) {
      return Icons.set_meal;
    } else if (nama.contains('sayur') ||
        nama.contains('kangkung') ||
        nama.contains('bayam')) {
      return Icons.eco;
    } else if (nama.contains('bumbu') ||
        nama.contains('rempah') ||
        nama.contains('garam')) {
      return Icons.scatter_plot;
    } else if (nama.contains('minyak') || nama.contains('santan')) {
      return Icons.opacity;
    } else if (nama.contains('telur')) {
      return Icons.egg;
    } else {
      return Icons.restaurant;
    }
  }
}
