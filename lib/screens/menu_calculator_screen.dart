// File: lib/screens/menu_calculator_screen.dart

import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../models/shared_calculation_data.dart';
import '../services/menu_calculator_service.dart';
import '../widgets/menu_input_widget.dart';
import '../widgets/menu_ingredient_selector_widget.dart';
import '../widgets/menu_composition_list_widget.dart';
import '../widgets/menu_calculation_result_widget.dart';

class MenuCalculatorScreen extends StatefulWidget {
  final SharedCalculationData sharedData;

  const MenuCalculatorScreen({
    super.key,
    required this.sharedData,
  });

  @override
  MenuCalculatorScreenState createState() => MenuCalculatorScreenState();
}

class MenuCalculatorScreenState extends State<MenuCalculatorScreen> {
  String _namaMenu = '';
  double _marginPercentage = 30.0; // Default margin 30%
  List<MenuComposition> _komposisiMenu = [];
  MenuCalculationResult? _calculationResult;

  @override
  void initState() {
    super.initState();
    _hitungMenu();
  }

  void _hitungMenu() {
    // Validasi input minimum untuk racik menu
    if (_namaMenu.isEmpty || _komposisiMenu.isEmpty) {
      setState(() {
        _calculationResult = null;
      });
      return;
    }

    try {
      MenuItem menu = MenuItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaMenu: _namaMenu,
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      // Fokus pada perhitungan racik menu (resep), tidak mempengaruhi HPP Murni
      MenuCalculationResult result = MenuCalculatorService.calculateMenuCost(
        menu: menu,
        sharedData: widget.sharedData,
        marginPercentage: _marginPercentage,
      );

      setState(() {
        _calculationResult = result;
      });
    } catch (e) {
      setState(() {
        _calculationResult = MenuCalculationResult.error(
            'Error dalam perhitungan menu: ${e.toString()}');
      });
    }
  }

  void _tambahKomposisi(String namaIngredient, double jumlah, String satuan,
      double hargaPerSatuan) {
    setState(() {
      _komposisiMenu.add(MenuComposition(
        namaIngredient: namaIngredient,
        jumlahDipakai: jumlah,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      ));
    });
    _hitungMenu();
  }

  void _hapusKomposisi(int index) {
    setState(() {
      if (index >= 0 && index < _komposisiMenu.length) {
        _komposisiMenu.removeAt(index);
      }
    });
    _hitungMenu();
  }

  void _updateNamaMenu(String nama) {
    setState(() {
      _namaMenu = nama;
    });
  }

  void _updateMargin(double margin) {
    setState(() {
      _marginPercentage = margin;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> availableIngredients =
        MenuCalculatorService.getAvailableIngredients(
            widget.sharedData.variableCosts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card 1: Input Utama (Nama Menu + Margin)
            MenuInputWidget(
              namaMenu: _namaMenu,
              marginPercentage: _marginPercentage,
              onNamaMenuChanged: _updateNamaMenu,
              onMarginChanged: _updateMargin,
              onDataChanged: _hitungMenu,
            ),

            const SizedBox(height: 16),

            // Card 2: Komposisi Menu (Dropdown Bahan + Input Jumlah + Dropdown Satuan + Tombol Tambah)
            MenuIngredientSelectorWidget(
              availableIngredients: availableIngredients,
              onAddIngredient: _tambahKomposisi,
            ),

            const SizedBox(height: 16),

            // Card 3: Komposisi Saat Ini (List View + Total Bahan Baku terpisah)
            MenuCompositionListWidget(
              komposisiMenu: _komposisiMenu,
              onRemoveItem: _hapusKomposisi,
            ),

            const SizedBox(height: 16),

            // Card 4: Perhitungan Menu (HPP + Harga Jual + Profit)
            MenuCalculationResultWidget(
              namaMenu: _namaMenu,
              calculationResult: _calculationResult,
            ),
          ],
        ),
      ),
    );
  }
}
