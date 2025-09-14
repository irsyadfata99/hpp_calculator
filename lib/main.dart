// lib/main.dart - SIMPLIFIED VERSION (NO fromEnvironment)
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
import 'services/data_sync_controller.dart';

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

  final DataSyncController _syncController = DataSyncController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initializing ${AppConstants.appName}...');

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      final operationalProvider =
          Provider.of<OperationalProvider>(context, listen: false);
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      debugPrint('📊 Initializing HPP Provider...');
      await hppProvider.initializeFromStorage();

      debugPrint('👥 Initializing Operational Provider...');
      await operationalProvider.initializeFromStorage();

      debugPrint('🍽️ Initializing Menu Provider...');
      await menuProvider.initializeFromStorage();

      _syncController.initialize(
        hppProvider: hppProvider,
        operationalProvider: operationalProvider,
        menuProvider: menuProvider,
      );

      debugPrint('✅ All providers initialized INDEPENDENTLY');

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = null;
        });

        // SIMPLIFIED AUTO DEBUG
        _startSimpleDebug();
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

  // SIMPLIFIED DEBUG - NO COMPLEX OPERATIONS
  void _startSimpleDebug() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_syncController.isInitialized) return;

      debugPrint('🔍 ===== SIMPLE DEBUG START =====');
      _syncController.printDetailedDebugInfo();
      _syncController.forceFullSync();
      debugPrint('🔍 ===== SIMPLE DEBUG END =====');
    });
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HPPCalculatorScreen(syncController: _syncController),
          OperationalCalculatorScreen(syncController: _syncController),
          MenuCalculatorScreen(syncController: _syncController),
        ],
      ),
      bottomNavigationBar:
          Consumer3<HPPProvider, OperationalProvider, MenuProvider>(
        builder:
            (context, hppProvider, operationalProvider, menuProvider, child) {
          return _buildBottomNavigationBar(
              hppProvider, operationalProvider, menuProvider);
        },
      ),
      // SIMPLE DEBUG BUTTON - ALWAYS SHOW FOR NOW
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('🔧 Manual Debug');
          _syncController.emergencyDiagnostic();
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.bug_report),
        mini: true,
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
        debugPrint('🔄 Tab switching: $_currentIndex → $index');
        setState(() {
          _currentIndex = index;
        });
        _syncController.syncOnTabSwitch();
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
