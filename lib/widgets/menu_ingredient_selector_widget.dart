// File: lib/widgets/menu_ingredient_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuIngredientSelectorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> availableIngredients;
  final Function(String, double, String, double) onAddIngredient;

  const MenuIngredientSelectorWidget({
    super.key,
    required this.availableIngredients,
    required this.onAddIngredient,
  });

  @override
  MenuIngredientSelectorWidgetState createState() =>
      MenuIngredientSelectorWidgetState();
}

class MenuIngredientSelectorWidgetState
    extends State<MenuIngredientSelectorWidget> {
  String? _selectedIngredient;
  String _selectedSatuan = 'kg';
  final _jumlahController = TextEditingController();

  static const List<String> _satuanOptions = ['kg', 'liter', 'unit', 'resep'];

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedIngredient = null;
      _selectedSatuan = 'kg';
    });
    _jumlahController.clear();
  }

  void _addIngredient() {
    if (_selectedIngredient != null && _jumlahController.text.isNotEmpty) {
      double? jumlah = double.tryParse(_jumlahController.text);
      if (jumlah != null && jumlah > 0) {
        var ingredient = widget.availableIngredients
            .firstWhere((item) => item['nama'] == _selectedIngredient);

        widget.onAddIngredient(
          ingredient['nama'],
          jumlah,
          _selectedSatuan,
          ingredient['hargaPerSatuan'],
        );

        _resetForm();
      }
    }
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

            // Content
            if (widget.availableIngredients.isEmpty)
              _buildEmptyIngredientsWarning()
            else
              _buildIngredientSelector(),
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
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add_shopping_cart,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Komposisi Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
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

  Widget _buildIngredientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Pilih Bahan
        _buildIngredientDropdown(),

        const SizedBox(height: 16),

        // Row untuk Jumlah dan Satuan
        Row(
          children: [
            // Input Jumlah
            Expanded(
              flex: 2,
              child: _buildJumlahInput(),
            ),
            const SizedBox(width: 12),
            // Dropdown Satuan
            Expanded(
              child: _buildSatuanDropdown(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Tombol Tambah
        _buildAddButton(),
      ],
    );
  }

  Widget _buildIngredientDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIngredient,
      decoration: const InputDecoration(
        labelText: 'Pilih Bahan',
        hintText: 'Pilih bahan dari daftar',
        prefixIcon: Icon(Icons.inventory),
      ),
      items: widget.availableIngredients.map((ingredient) {
        return DropdownMenuItem<String>(
          value: ingredient['nama'],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ingredient['nama'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Rp ${ingredient['hargaPerSatuan'].toStringAsFixed(0)}/${ingredient['satuan']}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedIngredient = value;
        });
      },
    );
  }

  Widget _buildJumlahInput() {
    return TextField(
      controller: _jumlahController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Jumlah',
        hintText: '0',
        prefixIcon: Icon(Icons.straighten),
      ),
    );
  }

  Widget _buildSatuanDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSatuan,
      decoration: const InputDecoration(
        labelText: 'Satuan',
        prefixIcon: Icon(Icons.scale),
      ),
      items: _satuanOptions.map((satuan) {
        return DropdownMenuItem<String>(
          value: satuan,
          child: Text(satuan),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSatuan = value ?? 'kg';
        });
      },
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            (_selectedIngredient != null && _jumlahController.text.isNotEmpty)
                ? _addIngredient
                : null,
        icon: const Icon(Icons.add),
        label: const Text('Tambah ke Menu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
