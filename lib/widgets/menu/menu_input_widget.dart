// File: lib/widgets/menu_input_widget.dart

import 'package:flutter/material.dart';

class MenuInputWidget extends StatefulWidget {
  final String namaMenu;
  final double marginPercentage;
  final Function(String) onNamaMenuChanged;
  final Function(double) onMarginChanged;
  final VoidCallback onDataChanged;

  const MenuInputWidget({
    super.key,
    required this.namaMenu,
    required this.marginPercentage,
    required this.onNamaMenuChanged,
    required this.onMarginChanged,
    required this.onDataChanged,
  });

  @override
  MenuInputWidgetState createState() => MenuInputWidgetState();
}

class MenuInputWidgetState extends State<MenuInputWidget> {
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
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.edit_note,
            color: Colors.blue[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Input Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
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
}
