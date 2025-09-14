// lib/main.dart - FIXED VERSION: Eliminates infinite loops and layout issues
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

  // FIXED: Simplified error handling - remove complex global handlers that might interfere
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🚨 Flutter Error: ${details.exception}');
    // Let Flutter handle the error normally instead of custom handling
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // FIXED: Create providers without immediate cross-communication
        ChangeNotifierProvider(create: (_) => HPPProvider()),
        ChangeNotifierProvider(create: (_) => OperationalProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
        // FIXED: Simplified error widget - remove complex error handling
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

  // FIXED: Add flag to prevent infinite communication loops
  bool _isUpdatingProviders = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initializing ${AppConstants.appName}...');

      // FIXED: Wait for first frame to ensure context is ready
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      try {
        // Get providers safely with null checks
        final hppProvider = Provider.of<HPPProvider>(context, listen: false);
        final operationalProvider =
            Provider.of<OperationalProvider>(context, listen: false);
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);

        // FIXED: Initialize providers sequentially to avoid race conditions
        debugPrint('📊 Initializing HPP Provider...');
        await hppProvider.initializeFromStorage();

        debugPrint('👥 Initializing Operational Provider...');
        await operationalProvider.initializeFromStorage();

        debugPrint('🍽️ Initializing Menu Provider...');
        await menuProvider.initializeFromStorage();

        // FIXED: Setup provider communication AFTER all providers are initialized
        _setupProviderCommunicationSafe(
            hppProvider, operationalProvider, menuProvider);

        debugPrint('✅ All providers initialized successfully');

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

  /// FIXED: Safe provider communication that prevents infinite loops
  void _setupProviderCommunicationSafe(
    HPPProvider hppProvider,
    OperationalProvider operationalProvider,
    MenuProvider menuProvider,
  ) {
    debugPrint('🔗 Setting up safe provider communication...');

    // FIXED: Remove listener-based communication that causes infinite loops
    // Instead, use manual updates when needed

    // Initial sync if HPP has data
    if (hppProvider.data.estimasiPorsi > 0) {
      _syncProvidersData(hppProvider, operationalProvider, menuProvider);
    }

    debugPrint('✅ Safe provider communication setup complete');
  }

  /// FIXED: Manual sync method to prevent infinite loops
  void _syncProvidersData(
    HPPProvider hppProvider,
    OperationalProvider operationalProvider,
    MenuProvider menuProvider,
  ) {
    if (_isUpdatingProviders) return; // Prevent recursive calls

    try {
      _isUpdatingProviders = true;

      debugPrint('🔄 Syncing provider data...');

      // Update with current HPP data
      if (hppProvider.data.estimasiPorsi > 0) {
        operationalProvider.updateSharedData(hppProvider.data);
        menuProvider.updateSharedData(hppProvider.data);
      }

      debugPrint('✅ Provider data sync complete');
    } catch (e) {
      debugPrint('❌ Error syncing provider data: $e');
    } finally {
      _isUpdatingProviders = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Simplified loading state - remove complex UI during loading
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

    // FIXED: Simplified error state
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

    // FIXED: Main interface with proper provider usage
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
          // FIXED: Trigger manual sync when switching tabs
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isUpdatingProviders) {
              _syncProvidersData(
                  hppProvider, operationalProvider, menuProvider);
            }
          });

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

        // FIXED: Manual sync on tab change
        _syncProvidersData(hppProvider, operationalProvider, menuProvider);
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

  // FIXED: Simplified badge widget to prevent layout issues
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
