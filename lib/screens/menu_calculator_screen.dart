// File: lib/screens/menu_calculator_screen.dart

import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../models/karyawan_data.dart';
import '../services/menu_calculator_service.dart';
import '../widgets/menu_composition_widget.dart';
import '../widgets/menu_result_widget.dart';

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
    if (_namaMenu.isEmpty || _komposisiMenu.isEmpty) {
      setState(() {
        _calculationResult = null;
      });
      return;
    }

    MenuItem menu = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      namaMenu: _namaMenu,
      komposisi: _komposisiMenu,
      createdAt: DateTime.now(),
    );

    MenuCalculationResult result = MenuCalculatorService.calculateMenuCost(
      menu: menu,
      sharedData: widget.sharedData,
      marginPercentage: _marginPercentage,
    );

    setState(() {
      _calculationResult = result;
    });
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
      _komposisiMenu.removeAt(index);
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
            // Widget 1: Input Menu dan Komposisi
            MenuCompositionWidget(
              namaMenu: _namaMenu,
              marginPercentage: _marginPercentage,
              komposisiMenu: _komposisiMenu,
              availableIngredients: availableIngredients,
              onNamaMenuChanged: _updateNamaMenu,
              onMarginChanged: _updateMargin,
              onDataChanged: _hitungMenu,
              onAddKomposisi: _tambahKomposisi,
              onRemoveKomposisi: _hapusKomposisi,
            ),

            const SizedBox(height: 16),

            // Widget 2: Hasil Perhitungan
            MenuResultWidget(
              namaMenu: _namaMenu,
              calculationResult: _calculationResult,
            ),
          ],
        ),
      ),
    );
  }
}
