// File: lib/widgets/menu_composition_widget.dart

import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_calculator_service.dart';

class MenuCompositionWidget extends StatefulWidget {
  final String namaMenu;
  final double marginPercentage;
  final List<MenuComposition> komposisiMenu;
  final List<Map<String, dynamic>> availableIngredients;
  final Function(String) onNamaMenuChanged;
  final Function(double) onMarginChanged;
  final VoidCallback onDataChanged;
  final Function(String, double, String, double) onAddKomposisi;
  final Function(int) onRemoveKomposisi;

  const MenuCompositionWidget({
    super.key,
    required this.namaMenu,
    required this.marginPercentage,
    required this.komposisiMenu,
    required this.availableIngredients,
    required this.onNamaMenuChanged,
    required this.onMarginChanged,
    required this.onDataChanged,
    required this.onAddKomposisi,
    required this.onRemoveKomposisi,
  });

  @override
  MenuCompositionWidgetState createState() => MenuCompositionWidgetState();
}

class MenuCompositionWidgetState extends State<MenuCompositionWidget> {
  final _namaMenuController = TextEditingController();
  final _marginController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _namaMenuController.text = widget.namaMenu;
    _marginController.text = widget.marginPercentage.toString();
  }

  @override
  void dispose() {
    _namaMenuController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // Input Nama Menu
            _buildNamaMenuInput(),

            const SizedBox(height: 16),

            // Input Margin
            _buildMarginInput(),

            const SizedBox(height: 16),

            // Komposisi Menu
            _buildKomposisiSection(),
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
            Icons.restaurant_menu,
            color: Colors.purple[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Racik Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNamaMenuInput() {
    return TextField(
      controller: _namaMenuController,
      decoration: const InputDecoration(
        labelText: 'Nama Menu',
        hintText: 'Contoh: Nasi Gudeg Spesial',
        prefixIcon: Icon(Icons.fastfood),
      ),
      onChanged: (value) {
        widget.onNamaMenuChanged(value);
        widget.onDataChanged();
      },
    );
  }

  Widget _buildMarginInput() {
    return TextField(
      controller: _marginController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Margin (%)',
        hintText: '30',
        prefixIcon: Icon(Icons.percent),
        suffixText: '%',
      ),
      onChanged: (value) {
        double? margin = double.tryParse(value);
        if (margin != null && margin >= 0) {
          widget.onMarginChanged(margin);
          widget.onDataChanged();
        }
      },
    );
  }

  Widget _buildKomposisiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komposisi Menu:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (widget.availableIngredients.isEmpty)
          _buildEmptyIngredientsWarning()
        else ...[
          // Dropdown untuk menambah ingredient
          _buildAddIngredientSection(),

          const SizedBox(height: 12),

          // List komposisi yang sudah ditambahkan
          if (widget.komposisiMenu.isNotEmpty) ...[
            const Text('Komposisi Saat Ini:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...widget.komposisiMenu.asMap().entries.map((entry) {
              int index = entry.key;
              MenuComposition item = entry.value;
              return _buildKomposisiItem(item, index);
            }),
            const SizedBox(height: 8),
            _buildTotalBahanBaku(),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyIngredientsWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Belum ada data bahan baku. Silakan lengkapi data Variable Cost terlebih dahulu.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddIngredientSection() {
    String? selectedIngredient;
    final jumlahController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Dropdown ingredient
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedIngredient,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Bahan',
                        isDense: true,
                      ),
                      items: widget.availableIngredients.map((ingredient) {
                        return DropdownMenuItem<String>(
                          value: ingredient['nama'],
                          child: Text(
                              '${ingredient['nama']} (${ingredient['satuan']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateLocal(() {
                          selectedIngredient = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Input jumlah
                  Expanded(
                    child: TextField(
                      controller: jumlahController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedIngredient != null
                      ? () {
                          double? jumlah =
                              double.tryParse(jumlahController.text);
                          if (jumlah != null && jumlah > 0) {
                            var ingredient = widget.availableIngredients
                                .firstWhere((item) =>
                                    item['nama'] == selectedIngredient);
                            widget.onAddKomposisi(
                              ingredient['nama'],
                              jumlah,
                              ingredient['satuan'],
                              ingredient['hargaPerSatuan'],
                            );
                            jumlahController.clear();
                            setStateLocal(() {
                              selectedIngredient = null;
                            });
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah ke Menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKomposisiItem(MenuComposition item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.namaIngredient,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${item.jumlahDipakai} ${item.satuan} × ${MenuCalculatorService.formatRupiah(item.hargaPerSatuan)} = ${MenuCalculatorService.formatRupiah(item.totalCost)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onRemoveKomposisi(index),
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBahanBaku() {
    double total =
        widget.komposisiMenu.fold(0.0, (sum, item) => sum + item.totalCost);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Bahan Baku:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            MenuCalculatorService.formatRupiah(total),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.purple[700]),
          ),
        ],
      ),
    );
  }
}
