// lib/screens/menu_calculator_screen.dart - SAFE FALLBACK VERSION
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MenuCalculatorScreen extends StatefulWidget {
  const MenuCalculatorScreen({super.key});

  @override
  MenuCalculatorScreenState createState() => MenuCalculatorScreenState();
}

class MenuCalculatorScreenState extends State<MenuCalculatorScreen> {
  String _namaMenu = '';
  double _marginPercentage = 30.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Calculator'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Simple menu input without complex calculations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nama Menu',
                        hintText: 'Masukkan nama menu',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _namaMenu = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Margin (%)',
                        hintText: '30',
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        double? margin = double.tryParse(value);
                        if (margin != null) {
                          setState(() {
                            _marginPercentage = margin;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.construction,
                        size: 48, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text(
                      'Menu Calculator',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nama Menu: ${_namaMenu.isEmpty ? "Belum diisi" : _namaMenu}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Margin: ${_marginPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Full functionality akan tersedia setelah integrasi Provider complete (Tahap 4)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
