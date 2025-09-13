// lib/main.dart - FIXED PROVIDER MIGRATION
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
        // Core HPP Provider - Primary data source
        ChangeNotifierProvider(create: (_) => HPPProvider()),

        // Operational Provider - Depends on HPP data
        ChangeNotifierProvider(create: (_) => OperationalProvider()),

        // Menu Provider - Depends on HPP data
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
      debugPrint(
          '🚀 Initializing ${AppConstants.appName} with Full Provider Pattern...');

      // Wait for first frame to ensure providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // Get all providers
          final hppProvider = Provider.of<HPPProvider>(context, listen: false);
          final operationalProvider =
              Provider.of<OperationalProvider>(context, listen: false);
          final menuProvider =
              Provider.of<MenuProvider>(context, listen: false);

          // Initialize HPP Provider first (primary data source)
          debugPrint('📊 Initializing HPP Provider...');
          await hppProvider.initializeFromStorage();

          // Initialize Operational Provider and setup communication with HPP
          debugPrint('👥 Initializing Operational Provider...');
          await operationalProvider.initializeFromStorage();

          // FIXED: Wait for HPP to be ready before updating operational
          if (hppProvider.data.estimasiPorsi > 0) {
            operationalProvider.updateSharedData(hppProvider.data);
          }

          // Initialize Menu Provider and setup communication with HPP
          debugPrint('🍽️ Initializing Menu Provider...');
          await menuProvider.initializeFromStorage();

          // FIXED: Wait for HPP to be ready before updating menu
          if (hppProvider.data.estimasiPorsi > 0) {
            menuProvider.updateSharedData(hppProvider.data);
          }

          // Setup provider-to-provider listeners
          _setupProviderCommunication(
              hppProvider, operationalProvider, menuProvider);

          debugPrint('✅ Full Provider Migration completed successfully');
          debugPrint('📈 App Status:');
          debugPrint('   - HPP Items: ${hppProvider.data.totalItemCount}');
          debugPrint('   - Employees: ${operationalProvider.karyawanCount}');
          debugPrint('   - Menu History: ${menuProvider.historyCount}');

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

  /// FIXED: Setup provider-to-provider communication with proper debouncing
  void _setupProviderCommunication(
    HPPProvider hppProvider,
    OperationalProvider operationalProvider,
    MenuProvider menuProvider,
  ) {
    debugPrint('🔗 Setting up provider-to-provider communication...');

    // FIXED: Add listener with debouncing to prevent infinite loops
    hppProvider.addListener(() {
      // Only update if providers are initialized and data has actually changed
      if (_isInitialized && hppProvider.data.estimasiPorsi > 0) {
        // Update operational provider when HPP data changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            operationalProvider.updateSharedData(hppProvider.data);
            menuProvider.updateSharedData(hppProvider.data);
          }
        });
      }
    });

    debugPrint('✅ Provider communication setup complete');
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
              const SizedBox(height: 8),
              const Text(
                '🔄 Initializing Provider Pattern...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  'Provider Initialization Failed',
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
                        'Provider Error Details:',
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
                      label: const Text('Retry Provider Init'),
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
                      label: const Text('Continue Anyway'),
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

    // Main app interface with full Provider pattern
    return Consumer3<HPPProvider, OperationalProvider, MenuProvider>(
      builder:
          (context, hppProvider, operationalProvider, menuProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              HPPCalculatorScreen(), // Uses HPPProvider
              OperationalCalculatorScreen(), // Uses OperationalProvider + HPPProvider
              MenuCalculatorScreen(), // Uses MenuProvider + HPPProvider
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(
              hppProvider, operationalProvider, menuProvider),
        );
      },
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

        // Log navigation with provider status
        debugPrint('📱 Navigated to tab $index:');
        switch (index) {
          case 0:
            debugPrint(
                '   HPP Calculator - ${hppProvider.data.totalItemCount} items');
            break;
          case 1:
            debugPrint(
                '   Operational - ${operationalProvider.karyawanCount} employees');
            break;
          case 2:
            debugPrint('   Menu - ${menuProvider.historyCount} menu history');
            break;
        }
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
          icon: Stack(
            children: [
              const Icon(Icons.business),
              if (operationalProvider.hasKaryawan)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${operationalProvider.karyawanCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          activeIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).primaryColor,
                ),
                if (operationalProvider.hasKaryawan)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${operationalProvider.karyawanCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          label: 'Operational',
          tooltip: 'Kelola Biaya Operasional & Karyawan',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.restaurant_menu),
              if (menuProvider.hasMenuHistory)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${menuProvider.historyCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          activeIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).primaryColor,
                ),
                if (menuProvider.hasMenuHistory)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${menuProvider.historyCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          label: 'Menu',
          tooltip: 'Kalkulasi Menu & Profit',
        ),
      ],
    );
  }
}
