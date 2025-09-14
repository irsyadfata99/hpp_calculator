// lib/main.dart - FIXED: COMPLETELY ELIMINATES ALL LOOPS
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

  // FIXED: Simplified error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🚨 Flutter Error: ${details.exception}');
  };

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
        builder: (context, widget) {
          return widget ?? const SizedBox.shrink();
        },
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

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      try {
        final hppProvider = Provider.of<HPPProvider>(context, listen: false);
        final operationalProvider =
            Provider.of<OperationalProvider>(context, listen: false);
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);

        // FIXED: Initialize providers INDEPENDENTLY - NO CROSS-COMMUNICATION
        debugPrint('📊 Initializing HPP Provider...');
        await hppProvider.initializeFromStorage();

        debugPrint('👥 Initializing Operational Provider...');
        await operationalProvider.initializeFromStorage();

        debugPrint('🍽️ Initializing Menu Provider...');
        await menuProvider.initializeFromStorage();

        // FIXED: NO AUTOMATIC SYNCING AT ALL
        debugPrint('✅ All providers initialized INDEPENDENTLY');

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _initError = null;
          });
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error during provider initialization: $e');
        debugPrint('Stack trace: $stackTrace');

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _initError = e.toString();
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Critical initialization error: $e');
      debugPrint('Stack trace: $stackTrace');

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
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading HPP Calculator...'),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Error',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_initError!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitialized = false;
                      _initError = null;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // FIXED: COMPLETELY REMOVED ALL AUTOMATIC SYNCING
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HPPCalculatorScreen(),
          OperationalCalculatorScreen(),
          MenuCalculatorScreen(),
        ],
      ),
      bottomNavigationBar:
          Consumer3<HPPProvider, OperationalProvider, MenuProvider>(
        builder:
            (context, hppProvider, operationalProvider, menuProvider, child) {
          // FIXED: NO SYNCING HERE - ONLY UI BUILDING
          return _buildBottomNavigationBar(
              hppProvider, operationalProvider, menuProvider);
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    HPPProvider hppProvider,
    OperationalProvider operationalProvider,
    MenuProvider menuProvider,
  ) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        // FIXED: NO SYNCING ON TAB CHANGES
      },
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: 'HPP Calculator',
          tooltip: 'Hitung Harga Pokok Penjualan',
        ),
        BottomNavigationBarItem(
          icon:
              _buildTabIcon(Icons.business, operationalProvider.karyawanCount),
          label: 'Operational',
          tooltip: 'Kelola Biaya Operasional & Karyawan',
        ),
        BottomNavigationBarItem(
          icon: _buildTabIcon(Icons.restaurant_menu, menuProvider.historyCount),
          label: 'Menu & Profit',
          tooltip: 'Kalkulasi Menu & Keuntungan',
        ),
      ],
    );
  }

  Widget _buildTabIcon(IconData icon, int count) {
    if (count <= 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
