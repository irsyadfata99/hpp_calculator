// lib/main.dart - CRITICAL FIX: Anti-Loop Provider Architecture + Circular Dependency Protection
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
        // CRITICAL FIX: HPP Provider as root (no dependencies)
        ChangeNotifierProvider(create: (_) => HPPProvider()),

        // CRITICAL FIX: Operational depends on HPP with enhanced anti-loop protection
        ChangeNotifierProxyProvider<HPPProvider, OperationalProvider>(
          create: (_) => OperationalProvider(),
          update: (context, hppProvider, operationalProvider) {
            // CRITICAL FIX: Enhanced anti-loop mechanism with null safety
            if (operationalProvider == null) {
              return OperationalProvider();
            }

            // CRITICAL FIX: Enhanced version checking with range validation
            final currentHppVersion = hppProvider.dataVersion;
            final lastProcessedVersion = operationalProvider.lastHppVersion;

            // CRITICAL FIX: Prevent cascading updates and infinite loops
            if (lastProcessedVersion == currentHppVersion) {
              return operationalProvider; // No change needed
            }

            // CRITICAL FIX: Detect potential infinite loop scenarios
            if (currentHppVersion - lastProcessedVersion > 10) {
              debugPrint(
                  '⚠️ CRITICAL: Large version jump detected in HPP→Operational chain. Potential infinite loop prevented.');
              return operationalProvider; // Skip update to prevent loop
            }

            // CRITICAL FIX: Rate limiting - prevent too frequent updates
            final now = DateTime.now();
            if (operationalProvider._lastUpdateTime != null &&
                now
                        .difference(operationalProvider._lastUpdateTime!)
                        .inMilliseconds <
                    100) {
              debugPrint('⚠️ Rate limiting: HPP→Operational update throttled');
              return operationalProvider; // Throttle rapid updates
            }

            // Safe update with error handling
            try {
              operationalProvider.updateFromHPP(
                  hppProvider.data, currentHppVersion);
              operationalProvider._lastUpdateTime = now;
              debugPrint('✅ Safe HPP→Operational update: v$currentHppVersion');
            } catch (e) {
              debugPrint('❌ Error in HPP→Operational update: $e');
              // Return existing provider to prevent cascade failure
            }

            return operationalProvider;
          },
        ),

        // CRITICAL FIX: Menu depends on both HPP and Operational with enhanced anti-loop protection
        ChangeNotifierProxyProvider2<HPPProvider, OperationalProvider,
            MenuProvider>(
          create: (_) => MenuProvider(),
          update: (context, hppProvider, operationalProvider, menuProvider) {
            // CRITICAL FIX: Enhanced anti-loop mechanism with comprehensive checks
            if (menuProvider == null) {
              return MenuProvider();
            }

            final currentHppVersion = hppProvider.dataVersion;
            final currentOpVersion = operationalProvider.dataVersion;
            final lastHppVersion = menuProvider.lastHppVersion;
            final lastOpVersion = menuProvider.lastOpVersion;

            // CRITICAL FIX: Enhanced version validation
            bool hppChanged = lastHppVersion != currentHppVersion;
            bool opChanged = lastOpVersion != currentOpVersion;

            if (!hppChanged && !opChanged) {
              return menuProvider; // No changes detected
            }

            // CRITICAL FIX: Detect and prevent cascade loops
            if (hppChanged && (currentHppVersion - lastHppVersion) > 10) {
              debugPrint(
                  '⚠️ CRITICAL: Large version jump detected in HPP→Menu chain. Potential infinite loop prevented.');
              return menuProvider;
            }

            if (opChanged && (currentOpVersion - lastOpVersion) > 10) {
              debugPrint(
                  '⚠️ CRITICAL: Large version jump detected in Operational→Menu chain. Potential infinite loop prevented.');
              return menuProvider;
            }

            // CRITICAL FIX: Enhanced rate limiting with separate timers
            final now = DateTime.now();
            if (menuProvider._lastUpdateTime != null &&
                now.difference(menuProvider._lastUpdateTime!).inMilliseconds <
                    200) {
              debugPrint('⚠️ Rate limiting: Menu update throttled');
              return menuProvider;
            }

            // CRITICAL FIX: Circuit breaker pattern - if too many rapid updates, pause
            if (menuProvider._updateCount > 20) {
              if (menuProvider._lastResetTime == null ||
                  now.difference(menuProvider._lastResetTime!).inSeconds < 5) {
                debugPrint(
                    '⚠️ CIRCUIT BREAKER: Too many Menu updates, pausing');
                return menuProvider;
              } else {
                // Reset counter after cooldown period
                menuProvider._updateCount = 0;
                menuProvider._lastResetTime = now;
              }
            }

            // Safe update with comprehensive error handling
            try {
              menuProvider.scheduleUpdate(
                hppData: hppProvider.data,
                hppVersion: currentHppVersion,
                operationalData: operationalProvider.lastCalculationResult,
                opVersion: currentOpVersion,
              );

              menuProvider._lastUpdateTime = now;
              menuProvider._updateCount++;

              debugPrint(
                  '✅ Safe Menu update: HPP v$currentHppVersion, OP v$currentOpVersion');
            } catch (e) {
              debugPrint('❌ Error in Menu update: $e');
              // Return existing provider to prevent cascade failure
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
  bool _isInitializing = false;

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
      // CRITICAL FIX: Extended delay to allow provider setup to complete
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      // CRITICAL FIX: Sequential initialization with enhanced error handling
      debugPrint('🚀 Starting app initialization...');

      // Initialize HPP first (root dependency)
      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      await hppProvider.initializeFromStorage();
      debugPrint('✅ HPP Provider initialized');

      // Wait and check if still mounted
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));

        // Initialize Operational (depends on HPP)
        final operationalProvider =
            Provider.of<OperationalProvider>(context, listen: false);
        await operationalProvider.initializeFromStorage();
        debugPrint('✅ Operational Provider initialized');
      }

      // Wait and check if still mounted
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));

        // Initialize Menu (depends on both HPP and Operational)
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);
        await menuProvider.initializeFromStorage();
        debugPrint('✅ Menu Provider initialized');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint(
            '✅ App initialized successfully - Enhanced anti-loop architecture active');
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
              Text('Initializing enhanced anti-loop architecture...',
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

// CRITICAL FIX: Extension classes to add tracking fields to providers
extension OperationalProviderTracking on OperationalProvider {
  static final Map<OperationalProvider, DateTime?> _lastUpdateTimes = {};

  DateTime? get _lastUpdateTime => _lastUpdateTimes[this];
  set _lastUpdateTime(DateTime? time) => _lastUpdateTimes[this] = time;
}

extension MenuProviderTracking on MenuProvider {
  static final Map<MenuProvider, DateTime?> _lastUpdateTimes = {};
  static final Map<MenuProvider, DateTime?> _lastResetTimes = {};
  static final Map<MenuProvider, int> _updateCounts = {};

  DateTime? get _lastUpdateTime => _lastUpdateTimes[this];
  set _lastUpdateTime(DateTime? time) => _lastUpdateTimes[this] = time;

  DateTime? get _lastResetTime => _lastResetTimes[this];
  set _lastResetTime(DateTime? time) => _lastResetTimes[this] = time;

  int get _updateCount => _updateCounts[this] ?? 0;
  set _updateCount(int count) => _updateCounts[this] = count;
}
