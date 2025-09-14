// lib/providers/app_state_provider.dart - CENTRALIZED STATE MANAGEMENT
import 'package:flutter/foundation.dart';
import '../models/shared_calculation_data.dart';
import '../models/karyawan_data.dart';
import '../models/menu_model.dart';
import '../services/hpp_calculator_service.dart';
import '../services/operational_calculator_service.dart';
import '../services/menu_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

// SIMPLIFIED: Single state provider instead of 3 separate providers
class AppStateProvider with ChangeNotifier {
  // Core data
  SharedCalculationData _sharedData = SharedCalculationData();

  // Menu specific data
  String _namaMenu = '';
  double _marginPercentage = AppConstants.defaultMargin;
  List<MenuComposition> _komposisiMenu = [];
  List<MenuItem> _menuHistory = [];

  // Calculation results
  HPPCalculationResult? _hppResult;
  OperationalCalculationResult? _operationalResult;
  MenuCalculationResult? _menuResult;

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  // DateTime? _lastUpdateTime;

  // SIMPLIFIED: Single getter for all data
  SharedCalculationData get sharedData => _sharedData;
  String get namaMenu => _namaMenu;
  double get marginPercentage => _marginPercentage;
  List<MenuComposition> get komposisiMenu => _komposisiMenu;
  List<MenuItem> get menuHistory => _menuHistory;
  List<KaryawanData> get karyawan => _sharedData.karyawan;

  // Results getters
  HPPCalculationResult? get hppResult => _hppResult;
  OperationalCalculationResult? get operationalResult => _operationalResult;
  MenuCalculationResult? get menuResult => _menuResult;

  // State getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed getters
  int get karyawanCount => _sharedData.karyawan.length;
  int get historyCount => _menuHistory.length;
  int get ingredientCount => _komposisiMenu.length;
  bool get isMenuValid =>
      _namaMenu.trim().isNotEmpty && _komposisiMenu.isNotEmpty;

  // SIMPLIFIED: Single initialization method
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _sharedData = savedData;
      }

      final menuHistory = await StorageService.loadMenuHistory();
      _menuHistory = menuHistory;

      await _recalculateAll();
      debugPrint('✅ AppStateProvider initialized successfully');
      _setError(null);
    } catch (e) {
      _setError('Initialization error: ${e.toString()}');
      debugPrint('❌ AppStateProvider initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =================
  // HPP METHODS
  // =================

  Future<void> addVariableCost(
      String nama, double totalHarga, double jumlah, String satuan) async {
    try {
      _setLoading(true);

      final newCosts =
          List<Map<String, dynamic>>.from(_sharedData.variableCosts);
      newCosts.add({
        'nama': nama.trim(),
        'totalHarga': totalHarga,
        'jumlah': jumlah,
        'satuan': satuan,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _sharedData = _sharedData.copyWith(variableCosts: newCosts);
      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error adding variable cost: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeVariableCost(int index) async {
    if (index < 0 || index >= _sharedData.variableCosts.length) return;

    try {
      _setLoading(true);

      final newCosts =
          List<Map<String, dynamic>>.from(_sharedData.variableCosts);
      newCosts.removeAt(index);

      _sharedData = _sharedData.copyWith(variableCosts: newCosts);
      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error removing variable cost: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFixedCost(String jenis, double nominal) async {
    try {
      _setLoading(true);

      final newCosts = List<Map<String, dynamic>>.from(_sharedData.fixedCosts);
      newCosts.add({
        'jenis': jenis.trim(),
        'nominal': nominal,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _sharedData = _sharedData.copyWith(fixedCosts: newCosts);
      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error adding fixed cost: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFixedCost(int index) async {
    if (index < 0 || index >= _sharedData.fixedCosts.length) return;

    try {
      _setLoading(true);

      final newCosts = List<Map<String, dynamic>>.from(_sharedData.fixedCosts);
      newCosts.removeAt(index);

      _sharedData = _sharedData.copyWith(fixedCosts: newCosts);
      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error removing fixed cost: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEstimasi(double porsi, double produksiBulanan) async {
    try {
      _setLoading(true);

      _sharedData = _sharedData.copyWith(
        estimasiPorsi: porsi,
        estimasiProduksiBulanan: produksiBulanan,
      );

      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error updating estimation: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // =================
  // OPERATIONAL METHODS
  // =================

  Future<void> addKaryawan(String nama, String jabatan, double gaji) async {
    try {
      _setLoading(true);

      final newKaryawan = KaryawanData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaKaryawan: nama.trim(),
        jabatan: jabatan.trim(),
        gajiBulanan: gaji,
        createdAt: DateTime.now(),
      );

      final newKaryawanList = [..._sharedData.karyawan, newKaryawan];
      _sharedData = _sharedData.copyWith(karyawan: newKaryawanList);

      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error adding karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeKaryawan(int index) async {
    if (index < 0 || index >= _sharedData.karyawan.length) return;

    try {
      _setLoading(true);

      final newKaryawanList = [..._sharedData.karyawan];
      newKaryawanList.removeAt(index);

      _sharedData = _sharedData.copyWith(karyawan: newKaryawanList);
      await _recalculateAll();
      await _autoSave();
      _setError(null);
    } catch (e) {
      _setError('Error removing karyawan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // =================
  // MENU METHODS
  // =================

  Future<void> updateNamaMenu(String nama) async {
    _namaMenu = nama.trim();
    await _recalculateMenu();
    notifyListeners();
  }

  Future<void> updateMarginPercentage(double margin) async {
    _marginPercentage = margin;
    await _recalculateMenu();
    notifyListeners();
  }

  Future<void> addIngredient(String namaIngredient, double jumlahDipakai,
      String satuan, double hargaPerSatuan) async {
    try {
      final newComposition = MenuComposition(
        namaIngredient: namaIngredient.trim(),
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      );

      _komposisiMenu = [..._komposisiMenu, newComposition];
      await _recalculateMenu();
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Error adding ingredient: ${e.toString()}');
    }
  }

  Future<void> removeIngredient(int index) async {
    if (index < 0 || index >= _komposisiMenu.length) return;

    try {
      final newList = [..._komposisiMenu];
      newList.removeAt(index);
      _komposisiMenu = newList;

      await _recalculateMenu();
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Error removing ingredient: ${e.toString()}');
    }
  }

  Future<void> saveCurrentMenu() async {
    if (_namaMenu.trim().isEmpty || _komposisiMenu.isEmpty) {
      _setError('Menu name and ingredients are required');
      return;
    }

    try {
      _setLoading(true);

      final menuItem = MenuItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaMenu: _namaMenu.trim(),
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      await StorageService.saveMenuToHistory(menuItem);
      _menuHistory = [menuItem, ..._menuHistory];

      // Clear current menu
      _namaMenu = '';
      _komposisiMenu = [];
      _menuResult = null;

      _setError(null);
      debugPrint('✅ Menu saved: ${menuItem.namaMenu}');
    } catch (e) {
      _setError('Error saving menu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void resetCurrentMenu() {
    _namaMenu = '';
    _komposisiMenu = [];
    _marginPercentage = AppConstants.defaultMargin;
    _menuResult = null;
    _setError(null);
    notifyListeners();
  }

  // =================
  // CALCULATION METHODS
  // =================

  Future<void> _recalculateAll() async {
    await _recalculateHPP();
    await _recalculateOperational();
    await _recalculateMenu();
  }

  Future<void> _recalculateHPP() async {
    try {
      _hppResult = HPPCalculatorService.calculateHPP(
        variableCosts: _sharedData.variableCosts,
        fixedCosts: _sharedData.fixedCosts,
        estimasiPorsiPerProduksi: _sharedData.estimasiPorsi,
        estimasiProduksiBulanan: _sharedData.estimasiProduksiBulanan,
      );

      if (_hppResult!.isValid) {
        _sharedData = _sharedData.copyWith(
          hppMurniPerPorsi: _hppResult!.hppMurniPerPorsi,
          biayaVariablePerPorsi: _hppResult!.biayaVariablePerPorsi,
          biayaFixedPerPorsi: _hppResult!.biayaFixedPerPorsi,
        );
      }
    } catch (e) {
      debugPrint('❌ HPP calculation error: $e');
      _hppResult = null;
    }
  }

  Future<void> _recalculateOperational() async {
    try {
      _operationalResult =
          OperationalCalculatorService.calculateOperationalCost(
        karyawan: _sharedData.karyawan,
        hppMurniPerPorsi: _sharedData.hppMurniPerPorsi,
        estimasiPorsiPerProduksi: _sharedData.estimasiPorsi,
        estimasiProduksiBulanan: _sharedData.estimasiProduksiBulanan,
      );

      if (_operationalResult!.isValid) {
        _sharedData = _sharedData.copyWith(
          totalOperationalCost: _operationalResult!.totalGajiBulanan,
          totalHargaSetelahOperational:
              _operationalResult!.totalHargaSetelahOperational,
        );
      }
    } catch (e) {
      debugPrint('❌ Operational calculation error: $e');
      _operationalResult = null;
    }
  }

  Future<void> _recalculateMenu() async {
    if (_komposisiMenu.isEmpty || _namaMenu.trim().isEmpty) {
      _menuResult = null;
      return;
    }

    try {
      final menuItem = MenuItem(
        id: 'temp',
        namaMenu: _namaMenu,
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      _menuResult = MenuCalculatorService.calculateMenuCost(
        menu: menuItem,
        sharedData: _sharedData,
        marginPercentage: _marginPercentage,
      );
    } catch (e) {
      debugPrint('❌ Menu calculation error: $e');
      _menuResult = null;
    }
  }

  // =================
  // UTILITY METHODS
  // =================

  List<Map<String, dynamic>> get availableIngredients {
    if (_sharedData.variableCosts.isEmpty) return [];

    try {
      return MenuCalculatorService.getAvailableIngredients(
          _sharedData.variableCosts);
    } catch (e) {
      debugPrint('❌ Error getting available ingredients: $e');
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetAllData() {
    _sharedData = SharedCalculationData();
    _namaMenu = '';
    _komposisiMenu = [];
    _menuHistory = [];
    _marginPercentage = AppConstants.defaultMargin;
    _hppResult = null;
    _operationalResult = null;
    _menuResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _autoSave() async {
    try {
      await StorageService.autoSave(_sharedData);
      debugPrint('💾 Auto-save completed');
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // =================
  // FORMATTED GETTERS
  // =================

  String get formattedTotalVariableCosts =>
      _sharedData.formatRupiah(_sharedData.totalVariableCosts);
  String get formattedTotalFixedCosts =>
      _sharedData.formatRupiah(_sharedData.totalFixedCosts);
  String get formattedHppMurni =>
      _sharedData.formatRupiah(_sharedData.hppMurniPerPorsi);
  String get formattedTotalGaji =>
      _sharedData.formatRupiah(_sharedData.totalOperationalCost);
  String get formattedOperationalPerPorsi =>
      _sharedData.formatRupiah(_sharedData.calculateOperationalCostPerPorsi());
  String get formattedTotalBahanBaku => MenuCalculatorService.formatRupiah(
      _komposisiMenu.fold(0.0, (sum, item) => sum + item.totalCost));
  String get formattedHargaJual => _menuResult?.isValid == true
      ? MenuCalculatorService.formatRupiah(_menuResult!.hargaSetelahMargin)
      : MenuCalculatorService.formatRupiah(0);
  String get formattedProfit => _menuResult?.isValid == true
      ? MenuCalculatorService.formatRupiah(_menuResult!.profitPerMenu)
      : MenuCalculatorService.formatRupiah(0);
}
