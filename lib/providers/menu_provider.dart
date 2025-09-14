// lib/providers/menu_provider.dart - FIXED ANTI-LOOP VERSION

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

  // FIXED: Anti-loop mechanism
  bool _isUpdatingSharedData = false;
  bool _isCalculating = false;
  DateTime? _lastUpdateTime;
  String? _lastDataHash; // To track actual data changes

  // FIXED: Static variable for tracking last ingredient count (moved outside method)
  static int _lastIngredientCount = -1;

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
  // FIXED: PUBLIC ERROR HANDLING METHODS
  // ===============================================

  /// FIXED: Public method for setting errors (called from UI)
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// FIXED: Public method for clearing errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// FIXED: Public method for setting loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ===============================================
  // PRIVATE HELPER METHODS (INTERNAL USE ONLY)
  // ===============================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// FIXED: Safe notify listeners method to prevent notifications during disposal
  void _safeNotifyListeners() {
    try {
      if (!mounted) return; // Check if provider is still mounted
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to notify listeners: $e');
    }
  }

  /// Check if the provider is still mounted (not disposed)
  bool get mounted => !_isDisposed;
  bool _isDisposed = false;

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
  // SHARED DATA INTEGRATION - FIXED WITH ANTI-LOOP MECHANISM
  // ===============================================

  void updateSharedData(SharedCalculationData newSharedData) {
    // FIXED: Prevent recursive updates
    if (_isUpdatingSharedData) {
      debugPrint(
          '🚫 MenuProvider.updateSharedData: Already updating, skipping...');
      return;
    }

    // FIXED: Add cooldown period
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
      if (timeSinceLastUpdate.inMilliseconds < 500) {
        // 500ms cooldown
        debugPrint(
            '🚫 MenuProvider.updateSharedData: Cooldown active, skipping...');
        return;
      }
    }

    // FIXED: Check if data actually changed using hash
    final newDataHash = _generateDataHash(newSharedData);
    if (_lastDataHash == newDataHash) {
      debugPrint(
          '🚫 MenuProvider.updateSharedData: No actual data changes, skipping...');
      return;
    }

    try {
      _isUpdatingSharedData = true;
      _lastUpdateTime = DateTime.now();
      _lastDataHash = newDataHash;

      debugPrint(
          '🔄 MenuProvider.updateSharedData called (${_lastUpdateTime})');
      debugPrint('📊 Data hash: ${newDataHash.substring(0, 8)}...');

      _sharedData = newSharedData;

      // FIXED: Only recalculate if we have meaningful menu data
      if (_shouldRecalculate()) {
        _recalculateMenu();
      } else {
        debugPrint(
            'ℹ️ MenuProvider: Skipping recalculation - insufficient menu data');
      }
    } catch (e) {
      debugPrint('❌ MenuProvider: Error updating shared data: $e');
      _setError('Error updating shared data: ${e.toString()}');
    } finally {
      _isUpdatingSharedData = false;
    }
  }

  // FIXED: Generate hash for data change detection
  String _generateDataHash(SharedCalculationData data) {
    return '${data.estimasiPorsi}_${data.estimasiProduksiBulanan}_${data.hppMurniPerPorsi}_${data.variableCosts.length}_${_komposisiMenu.length}_${_namaMenu}';
  }

  // FIXED: Determine if recalculation is needed
  bool _shouldRecalculate() {
    return _sharedData != null &&
        _komposisiMenu.isNotEmpty &&
        _namaMenu.trim().isNotEmpty &&
        !_isCalculating;
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

      // FIXED: Only show count if it changed (using class-level static variable)
      if (validIngredients.length != _lastIngredientCount) {
        debugPrint('📋 Available ingredients: ${validIngredients.length}');
        _lastIngredientCount = validIngredients.length;
      }

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

  // FIXED: Update addIngredient method di MenuProvider (line ~200-an)
// Replace method ini di lib/providers/menu_provider.dart

  Future<void> addIngredient(String namaIngredient, double jumlahDipakai,
      String satuan, double hargaPerSatuan) async {
    // DEBUG: Print what we're trying to add
    print('🔍 DEBUG addIngredient called with:');
    print('  namaIngredient: "$namaIngredient"');
    print('  jumlahDipakai: $jumlahDipakai');
    print('  satuan: "$satuan"');
    print('  hargaPerSatuan: $hargaPerSatuan');
    print('  Current _komposisiMenu length: ${_komposisiMenu.length}');

    // Validate inputs - FIXED: Different validation for unit prices
    final namaValidation = InputValidator.validateName(namaIngredient);
    if (namaValidation != null) {
      print('❌ Name validation failed: $namaValidation');
      _setError('Nama ingredient: $namaValidation');
      return;
    }

    final jumlahValidation =
        InputValidator.validateQuantity(jumlahDipakai.toString());
    if (jumlahValidation != null) {
      print('❌ Quantity validation failed: $jumlahValidation');
      _setError('Jumlah: $jumlahValidation');
      return;
    }

    // FIXED: Custom validation for unit prices in menu composition
    // Unit prices can be very small (e.g., Rp 30 per gram) due to unit conversion
    if (hargaPerSatuan <= 0) {
      print('❌ Unit price validation failed: must be positive');
      _setError('Harga per satuan harus lebih dari 0');
      return;
    }

    if (hargaPerSatuan > 1000000) {
      // Reasonable max: 1 million per unit
      print('❌ Unit price validation failed: too expensive');
      _setError(
          'Harga per satuan terlalu mahal (maksimal Rp 1,000,000 per unit)');
      return;
    }

    // Check for duplicate ingredient
    bool isDuplicate = _komposisiMenu.any((item) =>
        item.namaIngredient.toLowerCase().trim() ==
        namaIngredient.toLowerCase().trim());

    if (isDuplicate) {
      print('❌ Duplicate ingredient detected: $namaIngredient');
      _setError('Ingredient sudah ada dalam komposisi');
      return;
    }

    _setLoading(true);
    try {
      print('✅ All validations passed, creating MenuComposition...');

      final newComposition = MenuModel.MenuComposition(
        namaIngredient: namaIngredient.trim(),
        jumlahDipakai: jumlahDipakai,
        satuan: satuan,
        hargaPerSatuan: hargaPerSatuan,
      );

      print('✅ MenuComposition created successfully');
      print('  totalCost: ${newComposition.totalCost}');

      _komposisiMenu = [..._komposisiMenu, newComposition];

      print('✅ Added to _komposisiMenu');
      print('  New length: ${_komposisiMenu.length}');
      print('  Items in composition:');
      for (int i = 0; i < _komposisiMenu.length; i++) {
        final item = _komposisiMenu[i];
        print(
            '    [$i] ${item.namaIngredient}: ${item.jumlahDipakai} ${item.satuan} @ ${item.hargaPerSatuan} = ${item.totalCost}');
      }

      await _recalculateMenu();
      _setError(null);
      debugPrint('✅ Ingredient added to menu: $namaIngredient');

      // Force notify listeners
      notifyListeners();
      print('✅ notifyListeners() called');
    } catch (e) {
      print('❌ Exception in addIngredient: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _setError('Error adding ingredient: ${e.toString()}');
    } finally {
      _setLoading(false);
      print('🔚 addIngredient method completed');
    }
  }

  Future<void> updateIngredient(int index, String namaIngredient,
      double jumlahDipakai, String satuan, double hargaPerSatuan) async {
    if (index < 0 || index >= _komposisiMenu.length) {
      _setError('Index ingredient tidak valid');
      return;
    }

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
  // CORE CALCULATION METHOD - FIXED WITH ANTI-LOOP
  // ===============================================

  DateTime? _lastCalculationTime;

  Future<void> _recalculateMenu() async {
    // FIXED: More comprehensive prevention of simultaneous calculations
    if (_isCalculating || _isUpdatingSharedData) {
      debugPrint('🚫 Menu calculation blocked - operation in progress');
      return;
    }

    if (_sharedData == null ||
        _komposisiMenu.isEmpty ||
        _namaMenu.trim().isEmpty) {
      if (_lastCalculationResult != null) {
        _lastCalculationResult = null;
        _safeNotifyListeners();
      }
      return;
    }

    // FIXED: Add calculation rate limiting
    if (_lastCalculationTime != null) {
      final timeSinceLastCalc =
          DateTime.now().difference(_lastCalculationTime!);
      if (timeSinceLastCalc.inMilliseconds < 200) {
        // 200ms minimum between calculations
        debugPrint(
            '🚫 Menu calculation rate limited (${timeSinceLastCalc.inMilliseconds}ms)');
        return;
      }
    }

    try {
      _isCalculating = true;
      _lastCalculationTime = DateTime.now();

      debugPrint('🧮 Menu Calculation - START (${_lastCalculationTime})');

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

      // Only update if result is different
      if (_lastCalculationResult?.isValid != result.isValid ||
          (_lastCalculationResult?.hargaSetelahMargin !=
              result.hargaSetelahMargin)) {
        _lastCalculationResult = result;

        if (result.isValid) {
          debugPrint('✅ Menu Calculation - COMPLETED');
          debugPrint('  Menu: $_namaMenu');
          debugPrint(
              '  Bahan baku cost: Rp ${result.biayaBahanBakuMenu.toInt()}');
          debugPrint('  HPP murni: Rp ${result.hppMurniPerMenu.toInt()}');
          debugPrint(
              '  Selling price: Rp ${result.hargaSetelahMargin.toInt()}');
        } else {
          debugPrint('❌ Menu Calculation failed: ${result.errorMessage}');
        }

        _safeNotifyListeners();
      } else {
        debugPrint('ℹ️ Menu calculation result unchanged - skipping notify');
      }
    } catch (e) {
      if (_lastCalculationResult != null) {
        _lastCalculationResult = null;
        _safeNotifyListeners();
      }
      debugPrint('❌ Menu Calculation error: $e');
    } finally {
      _isCalculating = false;
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
  // RESET & CLEANUP METHODS
  // ===============================================

  void resetCurrentMenu() {
    _namaMenu = '';
    _komposisiMenu = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
    _errorMessage = null;

    // FIXED: Reset simplified flags
    _isCalculating = false;
    _lastCalculationTime = null;

    _safeNotifyListeners();
  }

  void resetAllData() {
    _namaMenu = '';
    _komposisiMenu = [];
    _menuHistory = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
    _errorMessage = null;

    // FIXED: Reset simplified flags
    _isCalculating = false;
    _lastCalculationTime = null;

    _safeNotifyListeners();
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
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
