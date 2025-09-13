// lib/main.dart - ENHANCED FOR TAHAP 1: DATA PERSISTENCE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/hpp_provider.dart';
import 'providers/operational_provider.dart';
import 'providers/menu_provider.dart';
import 'screens/hpp_calculator_screen.dart';
import 'screens/operational_calculator_screen.dart';
import 'screens/menu_calculator_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HPPProvider()),
        ChangeNotifierProvider(create: (_) => OperationalProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
      ),
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
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initializing ${AppConstants.appName}...');

      // Wait for first frame to ensure providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // Initialize HPP Provider with stored data
          final hppProvider = Provider.of<HPPProvider>(context, listen: false);
          await hppProvider.initializeFromStorage();

          // TODO: Initialize other providers in later phases
          // final operationalProvider = Provider.of<OperationalProvider>(context, listen: false);
          // await operationalProvider.initializeFromStorage();

          debugPrint('✅ App initialization completed successfully');

          if (mounted) {
            setState(() {
              _isInitialized = true;
              _initError = null;
            });
          }
        } catch (e) {
          debugPrint('❌ Provider initialization error: $e');
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _initError = e.toString();
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initialization
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading ${AppConstants.appName}...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen if initialization failed
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${AppConstants.appName} - Error'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _initError!,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isInitialized = false;
                          _initError = null;
                        });
                        _initializeApp();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isInitialized = true;
                          _initError = null;
                        });
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main app interface
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HPPCalculatorScreen(),
          OperationalCalculatorScreen(),
          MenuCalculatorScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calculate,
                color: Theme.of(context).primaryColor,
              ),
            ),
            label: 'HPP Calculator',
            tooltip: 'Hitung Harga Pokok Penjualan',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business,
                color: Theme.of(context).primaryColor,
              ),
            ),
            label: 'Operational',
            tooltip: 'Kelola Biaya Operasional',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).primaryColor,
              ),
            ),
            label: 'Menu',
            tooltip: 'Kalkulasi Menu',
          ),
        ],
      ),
    );
  }
}
