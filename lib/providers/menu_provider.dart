// lib/providers/menu_provider.dart - PHASE 1 FIX: Final Consumer (Receives All Updates)
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/menu_model.dart';
import '../models/shared_calculation_data.dart';
import '../services/menu_calculator_service.dart';
import '../services/operational_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class MenuProvider with ChangeNotifier {
  String _namaMenu = '';
  double _marginPercentage = AppConstants.defaultMargin;
  List<MenuComposition> _komposisiMenu = [];
  List<MenuItem> _menuHistory = [];
  String? _errorMessage;
  bool _isLoading = false;
  MenuCalculationResult? _lastCalculationResult;
  Timer? _autoSaveTimer;

  // FIXED: Combined data from HPP and Operational (read-only)
  SharedCalculationData _combinedData = SharedCalculationData();
  OperationalCalculationResult? _operationalResult;

  // Getters
  String get namaMenu => _namaMenu;
  double get marginPercentage => _marginPercentage;
  List<MenuComposition> get komposisiMenu => _komposisiMenu;
  List<MenuItem> get menuHistory => _menuHistory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  MenuCalculationResult? get lastCalculationResult => _lastCalculationResult;

  // INITIALIZATION - Only loads menu history
  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final menuHistory = await StorageService.loadMenuHistory();
      _menuHistory = menuHistory;

      debugPrint('✅ Menu Data loaded: ${_menuHistory.length} menu history');
      _setError(null);
    } catch (e) {
      _setError('Error loading menu data: ${e.toString()}');
      debugPrint('❌ Error loading menu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Receive updates from both HPP and Operational (called by ProxyProvider)
  void updateFromCalculations({
    required SharedCalculationData hppData,
    OperationalCalculationResult? operationalData,
  }) {
    try {
      _combinedData = hppData;
      _operationalResult = operationalData;

      // Update operational data in combined data if available
      if (operationalData != null && operationalData.isValid) {
        _combinedData = _combinedData.copyWith(
          totalOperationalCost: operationalData.totalGajiBulanan,
          totalHargaSetelahOperational:
              operationalData.totalHargaSetelahOperational,
        );
      }

      _recalculateMenu();
    } catch (e) {
      debugPrint('❌ Error updating menu calculations: $e');
    }
  }

  // FIXED: Safe available ingredients with type safety
  List<Map<String, dynamic>> get availableIngredients {
    if (_combinedData.variableCosts.isEmpty) {
      return [];
    }

    try {
      return MenuCalculatorService.getAvailableIngredients(
          _combinedData.variableCosts);
    } catch (e) {
      debugPrint('❌ Error getting available ingredients: $e');
      _setError('Error loading ingredient data: ${e.toString()}');
      return [];
    }
  }

  // MENU INPUT METHODS
  Future<void> updateNamaMenu(String nama) async {
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null && nama.isNotEmpty) {
      _setError('Nama menu: $namaValidation');
      return;
    }

    _namaMenu = nama.trim();
    _recalculateMenu();
    _setError(null);
    notifyListeners();
  }

  Future<void> updateMarginPercentage(double margin) async {
    final marginValidation =
        InputValidator.validatePercentage(margin.toString());
    if (marginValidation != null) {
      _setError('Margin: $marginValidation');
      return;
    }

    if (margin < AppConstants.minPercentage ||
        margin > AppConstants.maxPercentage) {
      _setError(
          'Margin harus antara ${AppConstants.minPercentage}% - ${AppConstants.maxPercentage}%');
      return;
    }

    _marginPercentage = margin;
    _recalculateMenu();
    _setError(null);
    notifyListeners();
  }

  // MENU COMPOSITION CRUD - FIXED: Type safe
  Future<void> addIngredient(String namaIngredient, double jumlahDipakai,
      String satuan, double hargaPerSatuan) async {
    // Validate inputs
    final namaValidation = InputValidator.validateName(namaIngredient);
    if (namaValidation != null) {
      _setError('Nama ingredient: $namaValidation');
      return;
    }

    final jumlahValidation =
        InputValidator.validateQuantity(jumlahDipakai.toString());
    if (jumlahValidation != null) {
      _setError('Jumlah: $jumlahValidation');
      return;
    }

    // FIXED: Custom validation for unit prices in menu composition
    if (hargaPerSatuan <= 0) {
      _setError('Harga per satuan harus lebih dari 0');
      return;
    }

    if (hargaPerSatuan > 1000000) {
      // Reasonable max: 1 million per unit
      _setError(
          'Harga per satuan terlalu mahal (maksimal Rp 1,000,000 per unit)');
      return;
    }

    // Check for duplicate ingredient
    bool isDuplicate = _komposisiMenu.any((item) =>
        item.namaIngredient.toLowerCase().trim() ==
        namaIngredient.toLowerCase().trim());

    if (isDuplicate) {
      _setError('Ingredient sudah ada dalam komposisi');
      return;
    }

    _setLoading(true);
    try {
      final newComposition = MenuComposition(
        namaIngredient: namaIngredient.trim(),
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      );

      _komposisiMenu = [..._komposisiMenu, newComposition];
      _recalculateMenu();
      _setError(null);

      // FIXED: Single notification
      notifyListeners();

      debugPrint('✅ Ingredient added to menu: $namaIngredient');
    } catch (e) {
      _setError('Error adding ingredient: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeIngredient(int index) async {
    if (index < 0 || index >= _komposisiMenu.length) {
      _setError('Index ingredient tidak valid');
      return;
    }

    _setLoading(true);
    try {
      final removedName = _komposisiMenu[index].namaIngredient;
      _komposisiMenu = [..._komposisiMenu]..removeAt(index);

      _recalculateMenu();
      _setError(null);

      // FIXED: Single notification
      notifyListeners();

      debugPrint('✅ Ingredient removed: $removedName');
    } catch (e) {
      _setError('Error removing ingredient: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // MENU MANAGEMENT
  Future<void> saveCurrentMenu() async {
    if (_namaMenu.trim().isEmpty) {
      _setError('Nama menu tidak boleh kosong');
      return;
    }

    if (_komposisiMenu.isEmpty) {
      _setError('Komposisi menu tidak boleh kosong');
      return;
    }

    _setLoading(true);
    try {
      final menuItem = MenuItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaMenu: _namaMenu.trim(),
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      await StorageService.saveMenuToHistory(menuItem);
      _menuHistory = [menuItem, ..._menuHistory];

      // Clear current menu for new entry
      _namaMenu = '';
      _komposisiMenu = [];
      _lastCalculationResult = null;

      _setError(null);

      // FIXED: Single notification
      notifyListeners();

      debugPrint('✅ Menu saved to history: ${menuItem.namaMenu}');
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
    _lastCalculationResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // CORE CALCULATION - FIXED: Simple without anti-loop mechanisms
  void _recalculateMenu() {
    if (_komposisiMenu.isEmpty || _namaMenu.trim().isEmpty) {
      _lastCalculationResult = null;
      return;
    }

    if (!_combinedData.isValidForCalculation) {
      _lastCalculationResult = null;
      return;
    }

    try {
      final menuItem = MenuItem(
        id: 'temp',
        namaMenu: _namaMenu,
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      _lastCalculationResult = MenuCalculatorService.calculateMenuCost(
        menu: menuItem,
        sharedData: _combinedData,
        marginPercentage: _marginPercentage,
      );
    } catch (e) {
      debugPrint('❌ Menu calculation error: $e');
      _lastCalculationResult = null;
    }
  }

  // ANALYSIS METHODS
  Map<String, dynamic> getMenuAnalysis() {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data menu belum lengkap untuk analisis',
      };
    }

    return MenuCalculatorService.analyzeMenuMargin(_lastCalculationResult!);
  }

  // VALIDATION METHODS
  bool get isMenuValid {
    return _namaMenu.trim().isNotEmpty &&
        _komposisiMenu.isNotEmpty &&
        MenuCalculatorService.isMenuCompositionValid(_komposisiMenu);
  }

  String? validateCurrentMenu() {
    if (_namaMenu.trim().isEmpty) {
      return 'Nama menu tidak boleh kosong';
    }

    if (_komposisiMenu.isEmpty) {
      return 'Menu harus memiliki minimal 1 bahan';
    }

    if (!MenuCalculatorService.isMenuCompositionValid(_komposisiMenu)) {
      return 'Ada data bahan yang tidak valid dalam komposisi';
    }

    return null; // Valid
  }

  // HELPER METHODS
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) notifyListeners(); // Only notify when starting to load
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetAllData() {
    _namaMenu = '';
    _komposisiMenu = [];
    _menuHistory = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // UTILITY GETTERS - FIXED: Type safe
  double get totalBahanBakuMenu {
    return _komposisiMenu.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  String get formattedTotalBahanBaku {
    return MenuCalculatorService.formatRupiah(totalBahanBakuMenu);
  }

  String get formattedHargaJual {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return MenuCalculatorService.formatRupiah(0);
    }
    return MenuCalculatorService.formatRupiah(
        _lastCalculationResult!.hargaSetelahMargin);
  }

  String get formattedProfit {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return MenuCalculatorService.formatRupiah(0);
    }
    return MenuCalculatorService.formatRupiah(
        _lastCalculationResult!.profitPerMenu);
  }

  bool get hasIngredients => _komposisiMenu.isNotEmpty;
  bool get hasMenuHistory => _menuHistory.isNotEmpty;
  bool get isCalculationReady =>
      _combinedData.isValidForCalculation &&
      _komposisiMenu.isNotEmpty &&
      _namaMenu.trim().isNotEmpty;
  int get ingredientCount => _komposisiMenu.length;
  int get historyCount => _menuHistory.length;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
