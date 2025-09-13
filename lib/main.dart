// lib/main.dart - TAHAP 3 IMPROVED VERSION WITH INDONESIAN TEXT
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
        // Core HPP Provider - Sumber data utama
        ChangeNotifierProvider(create: (_) => HPPProvider()),

        // Operational Provider - Bergantung pada data HPP
        ChangeNotifierProvider(create: (_) => OperationalProvider()),

        // Menu Provider - Bergantung pada data HPP
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
      debugPrint('🚀 Menginisialisasi ${AppConstants.appName}...');

      // Tunggu frame pertama untuk memastikan provider siap
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // Dapatkan semua provider
          final hppProvider = Provider.of<HPPProvider>(context, listen: false);
          final operationalProvider =
              Provider.of<OperationalProvider>(context, listen: false);
          final menuProvider =
              Provider.of<MenuProvider>(context, listen: false);

          // Inisialisasi HPP Provider terlebih dahulu (sumber data utama)
          debugPrint('📊 Menginisialisasi HPP Provider...');
          await hppProvider.initializeFromStorage();

          // Inisialisasi Operational Provider dan setup komunikasi dengan HPP
          debugPrint('👥 Menginisialisasi Operational Provider...');
          await operationalProvider.initializeFromStorage();

          // Tunggu HPP siap sebelum update operational
          if (hppProvider.data.estimasiPorsi > 0) {
            operationalProvider.updateSharedData(hppProvider.data);
          }

          // Inisialisasi Menu Provider dan setup komunikasi dengan HPP
          debugPrint('🍽️ Menginisialisasi Menu Provider...');
          await menuProvider.initializeFromStorage();

          // Tunggu HPP siap sebelum update menu
          if (hppProvider.data.estimasiPorsi > 0) {
            menuProvider.updateSharedData(hppProvider.data);
          }

          // Setup komunikasi antar provider
          _setupProviderCommunication(
              hppProvider, operationalProvider, menuProvider);

          debugPrint('✅ Migrasi Provider selesai sukses');
          debugPrint('📈 Status Aplikasi:');
          debugPrint('   - Item HPP: ${hppProvider.data.totalItemCount}');
          debugPrint('   - Karyawan: ${operationalProvider.karyawanCount}');
          debugPrint('   - Riwayat Menu: ${menuProvider.historyCount}');

          if (mounted) {
            setState(() {
              _isInitialized = true;
              _initError = null;
            });
          }
        } catch (e) {
          debugPrint('❌ Error inisialisasi provider: $e');
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _initError = e.toString();
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error inisialisasi aplikasi: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = e.toString();
        });
      }
    }
  }

  /// Setup komunikasi antar provider dengan debouncing yang proper
  void _setupProviderCommunication(
    HPPProvider hppProvider,
    OperationalProvider operationalProvider,
    MenuProvider menuProvider,
  ) {
    debugPrint('🔗 Menyiapkan komunikasi antar provider...');

    // Tambahkan listener dengan debouncing untuk mencegah infinite loop
    hppProvider.addListener(() {
      // Update hanya jika provider sudah terinisialisasi dan data benar-benar berubah
      if (_isInitialized && hppProvider.data.estimasiPorsi > 0) {
        // Update operational provider ketika data HPP berubah
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            operationalProvider.updateSharedData(hppProvider.data);
            menuProvider.updateSharedData(hppProvider.data);
          }
        });
      }
    });

    debugPrint('✅ Setup komunikasi provider selesai');
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen selama inisialisasi
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Memuat ${AppConstants.appName}...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versi ${AppConstants.appVersion}',
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
                '🔄 Menginisialisasi sistem...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilkan error screen jika inisialisasi gagal
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
                  'Gagal Menginisialisasi Aplikasi',
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
                        'Detail Error:',
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
                      label: const Text('Coba Lagi'),
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
                      label: const Text('Lanjutkan'),
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

    // Interface utama aplikasi dengan pola Provider lengkap
    return Consumer3<HPPProvider, OperationalProvider, MenuProvider>(
      builder:
          (context, hppProvider, operationalProvider, menuProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              HPPCalculatorScreen(), // Menggunakan HPPProvider
              OperationalCalculatorScreen(), // Menggunakan OperationalProvider + HPPProvider
              MenuCalculatorScreen(), // Menggunakan MenuProvider + HPPProvider
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

        // Log navigasi dengan status provider
        debugPrint('📱 Navigasi ke tab $index:');
        switch (index) {
          case 0:
            debugPrint(
                '   Kalkulator HPP - ${hppProvider.data.totalItemCount} item');
            break;
          case 1:
            debugPrint(
                '   Operasional - ${operationalProvider.karyawanCount} karyawan');
            break;
          case 2:
            debugPrint('   Menu - ${menuProvider.historyCount} riwayat menu');
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
          label: AppConstants.labelHPPCalculator,
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
          label: 'Operasional',
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
          label: 'Menu & Profit',
          tooltip: 'Kalkulasi Menu & Keuntungan',
        ),
      ],
    );
  }
}
