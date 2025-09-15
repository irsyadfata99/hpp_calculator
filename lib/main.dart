// lib/main.dart - FIXED: Simplified Architecture
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      // FIXED: Simple sequential initialization
      final hppProvider = Provider.of<HPPProvider>(context, listen: false);
      final operationalProvider =
          Provider.of<OperationalProvider>(context, listen: false);
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      await hppProvider.initializeFromStorage();
      await operationalProvider.initializeFromStorage();
      await menuProvider.initializeFromStorage();

      // FIXED: Simple one-time data sync without loops
      _performSimpleSync(hppProvider, operationalProvider, menuProvider);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  // FIXED: Simple sync without circular dependencies
  void _performSimpleSync(
      HPPProvider hpp, OperationalProvider ops, MenuProvider menu) {
    try {
      // Only sync if HPP has data
      if (hpp.data.variableCosts.isNotEmpty) {
        ops.updateFromHPP(hpp.data);
        menu.updateFromHPP(hpp.data);
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
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
              // FIXED: Simple sync on tab switch
              _performTabSwitchSync(
                  hppProvider, operationalProvider, menuProvider);
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

  void _performTabSwitchSync(
      HPPProvider hpp, OperationalProvider ops, MenuProvider menu) {
    try {
      if (hpp.data.variableCosts.isNotEmpty) {
        ops.updateFromHPP(hpp.data);
        menu.updateFromHPP(hpp.data);
      }
    } catch (e) {
      debugPrint('❌ Tab sync error: $e');
    }
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
