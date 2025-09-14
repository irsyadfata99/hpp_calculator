// lib/providers/menu_provider.dart - FIXED VERSION: COMPLETE NULL SAFETY
import 'package:flutter/foundation.dart';
import 'dart:async';
// FIXED: Use explicit imports to avoid ambiguous imports
import '../models/menu_model.dart' as MenuModel;
import '../models/shared_calculation_data.dart';
import '../services/menu_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class MenuProvider with ChangeNotifier {
  String _namaMenu = '';
  double _marginPercentage = AppConstants.defaultMargin;
  List<MenuModel.MenuComposition> _komposisiMenu = [];
  List<MenuModel.MenuItem> _menuHistory = [];
  String? _errorMessage;
  bool _isLoading = false;
  MenuCalculationResult? _lastCalculationResult;

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Reference to shared data (will be injected)
  SharedCalculationData? _sharedData;

  // Getters - FIXED: Use proper prefixed types
  String get namaMenu => _namaMenu;
  double get marginPercentage => _marginPercentage;
  List<MenuModel.MenuComposition> get komposisiMenu => _komposisiMenu;
  List<MenuModel.MenuItem> get menuHistory => _menuHistory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  MenuCalculationResult? get lastCalculationResult => _lastCalculationResult;
  SharedCalculationData? get sharedData => _sharedData;

  // ===============================================
  // INITIALIZATION WITH STORAGE
  // ===============================================

  Future<void> initializeFromStorage() async {
    _setLoading(true);
    try {
      final savedData = await StorageService.loadSharedData();
      if (savedData != null) {
        _sharedData = savedData;
      }

      final menuHistory = await StorageService.loadMenuHistory();
      _menuHistory = menuHistory;

      await _recalculateMenu();
      debugPrint(
          '✅ Menu Data loaded from storage: ${_menuHistory.length} menu history');
      _setError(null);
    } catch (e) {
      _setError('Error loading menu data: ${e.toString()}');
      debugPrint('❌ Error loading menu from storage: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // SHARED DATA INTEGRATION - FIXED NULL SAFETY
  // ===============================================

  void updateSharedData(SharedCalculationData newSharedData) {
    _sharedData = newSharedData;
    _recalculateMenu();
  }

  // FIXED: Enhanced availableIngredients with comprehensive null safety and validation
  List<Map<String, dynamic>> get availableIngredients {
    if (_sharedData == null || _sharedData!.variableCosts.isEmpty) {
      debugPrint('📋 No shared data or variable costs available');
      return []; // Return empty list instead of null
    }

    try {
      final ingredients = MenuCalculatorService.getAvailableIngredients(
          _sharedData!.variableCosts);

      // FIXED: Validate each ingredient has required fields with proper structure
      final validIngredients = ingredients.where((ingredient) {
        bool isValid = ingredient.containsKey('nama') &&
            ingredient.containsKey('totalHarga') &&
            ingredient.containsKey('jumlah') &&
            ingredient.containsKey('satuan') &&
            ingredient['nama'] != null &&
            ingredient['totalHarga'] != null &&
            ingredient['jumlah'] != null &&
            ingredient['satuan'] != null &&
            ingredient['nama'].toString().trim().isNotEmpty;

        if (!isValid) {
          debugPrint('⚠️ Invalid ingredient filtered out: $ingredient');
        }
        return isValid;
      }).toList();

      debugPrint('✅ Available ingredients: ${validIngredients.length}');
      return validIngredients;
    } catch (e) {
      debugPrint('❌ Error getting available ingredients: $e');
      _setError('Error loading ingredient data: ${e.toString()}');
      return [];
    }
  }

  // ===============================================
  // MENU INPUT METHODS
  // ===============================================

  Future<void> updateNamaMenu(String nama) async {
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null && nama.isNotEmpty) {
      _setError('Nama menu: $namaValidation');
      return;
    }

    _namaMenu = nama.trim();
    await _recalculateMenu();
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
    await _recalculateMenu();
    _setError(null);
    notifyListeners();
  }

  // ===============================================
  // MENU COMPOSITION CRUD METHODS - FIXED TYPES
  // ===============================================

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

    final hargaValidation =
        InputValidator.validatePrice(hargaPerSatuan.toString());
    if (hargaValidation != null) {
      _setError('Harga per satuan: $hargaValidation');
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
      // FIXED: Use prefixed class name
      final newComposition = MenuModel.MenuComposition(
        namaIngredient: namaIngredient.trim(),
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      );

      _komposisiMenu = [..._komposisiMenu, newComposition];
      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ Ingredient added to menu: $namaIngredient');
    } catch (e) {
      _setError('Error adding ingredient: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateIngredient(int index, String namaIngredient,
      double jumlahDipakai, String satuan, double hargaPerSatuan) async {
    if (index < 0 || index >= _komposisiMenu.length) {
      _setError('Index ingredient tidak valid');
      return;
    }

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

    final hargaValidation =
        InputValidator.validatePrice(hargaPerSatuan.toString());
    if (hargaValidation != null) {
      _setError('Harga per satuan: $hargaValidation');
      return;
    }

    _setLoading(true);
    try {
      final updatedComposition = MenuModel.MenuComposition(
        namaIngredient: namaIngredient.trim(),
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      );

      final newList = [..._komposisiMenu];
      newList[index] = updatedComposition;
      _komposisiMenu = newList;

      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ Ingredient updated: $namaIngredient');
    } catch (e) {
      _setError('Error updating ingredient: ${e.toString()}');
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
      final newList = [..._komposisiMenu];
      newList.removeAt(index);
      _komposisiMenu = newList;

      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ Ingredient removed: $removedName');
    } catch (e) {
      _setError('Error removing ingredient: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAllIngredients() async {
    _setLoading(true);
    try {
      _komposisiMenu = [];
      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ All ingredients cleared');
    } catch (e) {
      _setError('Error clearing ingredients: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // MENU MANAGEMENT - FIXED TYPES
  // ===============================================

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
      final menuItem = MenuModel.MenuItem(
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
      debugPrint('✅ Menu saved to history: ${menuItem.namaMenu}');
    } catch (e) {
      _setError('Error saving menu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMenuFromHistory(int index) async {
    if (index < 0 || index >= _menuHistory.length) {
      _setError('Index menu history tidak valid');
      return;
    }

    _setLoading(true);
    try {
      final menuItem = _menuHistory[index];
      _namaMenu = menuItem.namaMenu;
      _komposisiMenu = [...menuItem.komposisi];

      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ Menu loaded from history: ${menuItem.namaMenu}');
    } catch (e) {
      _setError('Error loading menu from history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMenuFromHistory(int index) async {
    if (index < 0 || index >= _menuHistory.length) {
      _setError('Index menu history tidak valid');
      return;
    }

    _setLoading(true);
    try {
      final deletedMenu = _menuHistory[index].namaMenu;
      _menuHistory = [..._menuHistory]..removeAt(index);

      _setError(null);
      debugPrint('✅ Menu deleted from history: $deletedMenu');
    } catch (e) {
      _setError('Error deleting menu from history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================
  // CORE CALCULATION METHOD - FIXED TYPES
  // ===============================================

  Future<void> _recalculateMenu() async {
    if (_sharedData == null ||
        _komposisiMenu.isEmpty ||
        _namaMenu.trim().isEmpty) {
      _lastCalculationResult = null;
      notifyListeners();
      return;
    }

    try {
      final menuItem = MenuModel.MenuItem(
        id: 'temp',
        namaMenu: _namaMenu,
        komposisi: _komposisiMenu,
        createdAt: DateTime.now(),
      );

      final result = MenuCalculatorService.calculateMenuCost(
        menu: menuItem,
        sharedData: _sharedData!,
        marginPercentage: _marginPercentage,
      );

      _lastCalculationResult = result;
      notifyListeners();
    } catch (e) {
      _lastCalculationResult = null;
      debugPrint('❌ Menu Calculation error: $e');
    }
  }

  // ===============================================
  // ANALYSIS METHODS
  // ===============================================

  Map<String, dynamic> getMenuAnalysis() {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data menu belum lengkap untuk analisis',
      };
    }

    return MenuCalculatorService.analyzeMenuMargin(_lastCalculationResult!);
  }

  Map<String, dynamic> getDetailedAnalysis() {
    if (_lastCalculationResult == null || !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data belum tersedia untuk analisis detail',
      };
    }

    return MenuCalculatorService.getMenuAnalysis(_lastCalculationResult!);
  }

  // ===============================================
  // VALIDATION METHODS - FIXED TYPE CASTING
  // ===============================================

  bool get isMenuValid {
    return _namaMenu.trim().isNotEmpty &&
        _komposisiMenu.isNotEmpty &&
        MenuCalculatorService.isMenuCompositionValid(
            _komposisiMenu.cast<MenuModel.MenuComposition>());
  }

  String? validateCurrentMenu() {
    if (_namaMenu.trim().isEmpty) {
      return 'Nama menu tidak boleh kosong';
    }

    if (_komposisiMenu.isEmpty) {
      return 'Menu harus memiliki minimal 1 bahan';
    }

    if (!MenuCalculatorService.isMenuCompositionValid(
        _komposisiMenu.cast<MenuModel.MenuComposition>())) {
      return 'Ada data bahan yang tidak valid dalam komposisi';
    }

    return null; // Valid
  }

  // ===============================================
  // HELPER METHODS - FIXED ACCESS LEVELS
  // ===============================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetCurrentMenu() {
    _namaMenu = '';
    _komposisiMenu = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
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

  // ===============================================
  // UTILITY GETTERS
  // ===============================================

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

  bool get isCalculationReady {
    return _sharedData != null &&
        _komposisiMenu.isNotEmpty &&
        _namaMenu.trim().isNotEmpty;
  }

  int get ingredientCount => _komposisiMenu.length;

  int get historyCount => _menuHistory.length;

  Map<String, dynamic> get calculationSummary {
    return {
      'namaMenu': _namaMenu,
      'totalIngredients': _komposisiMenu.length,
      'marginPercentage': _marginPercentage,
      'totalBahanBaku': totalBahanBakuMenu,
      'isValid': _lastCalculationResult?.isValid ?? false,
      'hasSharedData': _sharedData != null,
      'menuHistoryCount': _menuHistory.length,
      'lastCalculated': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
