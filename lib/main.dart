// File: lib/main.dart (Simplified)

import 'package:flutter/material.dart';
import 'screens/hpp_calculator_screen.dart';
import 'screens/operational_calculator_screen.dart';
import 'screens/menu_calculator_screen.dart';
import '../models/shared_calculation_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator HPP',
      theme: ThemeData(
        // Color Palette sesuai permintaan
        primaryColor: const Color(0xFF476EAE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF476EAE),
          secondary: const Color(0xFF48B3AF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF476EAE),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF476EAE),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late SharedCalculationData _sharedData;

  @override
  void initState() {
    super.initState();
    _sharedData = SharedCalculationData();
  }

  void _updateSharedData(SharedCalculationData newData) {
    setState(() {
      _sharedData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HPPCalculatorScreen(
            sharedData: _sharedData,
            onDataChanged: _updateSharedData,
          ),
          OperationalCalculatorScreen(sharedData: _sharedData),
          MenuCalculatorScreen(sharedData: _sharedData),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Penting untuk 3+ tabs
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'HPP Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Operational',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
