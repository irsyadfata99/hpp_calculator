// lib/main.dart - CRITICAL FIX: Anti-Loop Provider Architecture
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
        // FIXED: HPP Provider as root (no dependencies)
        ChangeNotifierProvider(create: (_) => HPPProvider()),

        // FIXED: Operational depends on HPP with anti-loop protection
        ChangeNotifierProxyProvider<HPPProvider, OperationalProvider>(
          create: (_) => OperationalProvider(),
          update: (context, hppProvider, operationalProvider) {
            // CRITICAL FIX: Anti-loop mechanism
            if (operationalProvider == null) {
              return OperationalProvider();
            }

            // Prevent update loops with version checking
            final currentHppVersion = hppProvider.dataVersion;
            if (operationalProvider.lastHppVersion != currentHppVersion) {
              // Only update if HPP data actually changed
              operationalProvider.updateFromHPP(
                  hppProvider.data, currentHppVersion);
            }

            return operationalProvider;
          },
        ),

        // FIXED: Menu depends on both HPP and Operational with anti-loop protection
        ChangeNotifierProxyProvider2<HPPProvider, OperationalProvider,
            MenuProvider>(
          create: (_) => MenuProvider(),
          update: (context, hppProvider, operationalProvider, menuProvider) {
            // CRITICAL FIX: Anti-loop mechanism
            if (menuProvider == null) {
              return MenuProvider();
            }

            final currentHppVersion = hppProvider.dataVersion;
            final currentOpVersion = operationalProvider.dataVersion;

            // Only update if either dependency actually changed
            if (menuProvider.lastHppVersion != currentHppVersion ||
                menuProvider.lastOpVersion != currentOpVersion) {
              // Debounce rapid updates
              menuProvider.scheduleUpdate(
                hppData: hppProvider.data,
                hppVersion: currentHppVersion,
                operationalData: operationalProvider.lastCalculationResult,
                opVersion: currentOpVersion,
              );
            }

            return menuProvider;
          },
        ),
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
  bool _isInitializing =
      false; // CRITICAL FIX: Prevent multiple initializations

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // CRITICAL FIX: Prevent multiple concurrent initializations
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // FIXED: Sequential initialization with error handling
      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      await hppProvider.initializeFromStorage();

      // Wait for operational provider to initialize
      if (mounted) {
        final operationalProvider =
            Provider.of<OperationalProvider>(context, listen: false);
        await operationalProvider.initializeFromStorage();
      }

      // Wait for menu provider to initialize
      if (mounted) {
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);
        await menuProvider.initializeFromStorage();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint(
            '✅ App initialized successfully - Anti-loop architecture active');
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized =
              true; // Still mark as initialized to prevent indefinite loading
        });
      }
    } finally {
      _isInitializing = false;
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
              SizedBox(height: 8),
              Text('Initializing anti-loop architecture...',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

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
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.calculate),
                label: 'HPP Calculator',
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(
                    Icons.business, operationalProvider.karyawanCount),
                label: 'Operational',
              ),
              BottomNavigationBarItem(
                icon: _buildTabIcon(
                    Icons.restaurant_menu, menuProvider.historyCount),
                label: 'Menu & Profit',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);

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
