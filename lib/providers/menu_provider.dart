// lib/providers/menu_provider.dart - FIXED: InputValidator Compatibility + Anti-Loop
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

  // CRITICAL FIX: Anti-loop & debouncing mechanisms
  SharedCalculationData _combinedData = SharedCalculationData();
  int _lastHppVersion = -1;
  int _lastOpVersion = -1;
  bool _isDisposed = false;
  bool _isUpdating = false;
  Timer? _updateDebounceTimer;

  // Getters
  String get namaMenu => _namaMenu;
  double get marginPercentage => _marginPercentage;
  List<MenuComposition> get komposisiMenu => _komposisiMenu;
  List<MenuItem> get menuHistory => _menuHistory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  MenuCalculationResult? get lastCalculationResult => _lastCalculationResult;
  int get lastHppVersion => _lastHppVersion;
  int get lastOpVersion => _lastOpVersion;

  // CRITICAL FIX: Safe async operation wrapper
  Future<T?> _safeAsyncOperation<T>(Future<T> Function() operation) async {
    if (_isDisposed || _isUpdating) return null;

    _isUpdating = true;
    try {
      final result = await operation();
      if (_isDisposed) return null;
      return result;
    } finally {
      if (!_isDisposed) {
        _isUpdating = false;
      }
    }
  }

  // CRITICAL FIX: Safe notification
  void _notifyListenersSafely() {
    if (_isDisposed || _isUpdating) return;
    notifyListeners();
  }

  // INITIALIZATION
  Future<void> initializeFromStorage() async {
    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        final menuHistory = await StorageService.loadMenuHistory();
        if (!_isDisposed) {
          _menuHistory = menuHistory;
          debugPrint('✅ Menu Data loaded: ${_menuHistory.length} menu history');
        }
        _setError(null);
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error loading menu data: ${e.toString()}');
          debugPrint('❌ Error loading menu: $e');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // CRITICAL FIX: Debounced update mechanism to prevent loops
  void scheduleUpdate({
    required SharedCalculationData hppData,
    required int hppVersion,
    OperationalCalculationResult? operationalData,
    required int opVersion,
  }) {
    if (_isDisposed) return;

    // CRITICAL FIX: Cancel previous update timer
    _updateDebounceTimer?.cancel();

    // CRITICAL FIX: Debounce rapid updates (300ms delay)
    _updateDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _performUpdate(
          hppData: hppData,
          hppVersion: hppVersion,
          operationalData: operationalData,
          opVersion: opVersion,
        );
      }
    });
  }

  // CRITICAL FIX: Actual update method with anti-loop protection
  void _performUpdate({
    required SharedCalculationData hppData,
    required int hppVersion,
    OperationalCalculationResult? operationalData,
    required int opVersion,
  }) {
    if (_isDisposed || _isUpdating) return;

    try {
      _isUpdating = true;

      // CRITICAL FIX: Only update if versions actually changed
      bool hppChanged = _lastHppVersion != hppVersion;
      bool opChanged = _lastOpVersion != opVersion;

      if (!hppChanged && !opChanged) {
        return; // No actual changes - prevent unnecessary updates
      }

      _combinedData = hppData;
      _lastHppVersion = hppVersion;
      _lastOpVersion = opVersion;

      // Update operational data in combined data if available
      if (operationalData != null && operationalData.isValid && !_isDisposed) {
        _combinedData = _combinedData.copyWith(
          totalOperationalCost: operationalData.totalGajiBulanan,
          totalHargaSetelahOperational:
              operationalData.totalHargaSetelahOperational,
        );
      }

      if (!_isDisposed) {
        _recalculateMenu();
        debugPrint('✅ Menu updated - HPP:$hppVersion, OP:$opVersion');
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Error updating menu calculations: $e');
      }
    } finally {
      _isUpdating = false;
      if (!_isDisposed) {
        _notifyListenersSafely();
      }
    }
  }

  // FIXED: Safe available ingredients with disposal check
  List<Map<String, dynamic>> get availableIngredients {
    if (_isDisposed || _combinedData.variableCosts.isEmpty) {
      return [];
    }

    try {
      return MenuCalculatorService.getAvailableIngredients(
          _combinedData.variableCosts);
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Error getting available ingredients: $e');
        _setError('Error loading ingredient data: ${e.toString()}');
      }
      return [];
    }
  }

  // MENU INPUT METHODS - FIXED: InputValidator compatibility
  Future<void> updateNamaMenu(String nama) async {
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null && nama.isNotEmpty) {
      _setError('Nama menu: $namaValidation');
      return;
    }

    if (_isDisposed) return;

    _namaMenu = nama.trim();
    _recalculateMenu();
    _setError(null);
    _notifyListenersSafely();
  }

  // FIXED: Use direct margin validation instead of string conversion
  Future<void> updateMarginPercentage(double margin) async {
    // FIXED: Call validateMargin directly with double
    final marginValidation = InputValidator.validateMargin(margin);
    if (marginValidation != null) {
      _setError('Margin: $marginValidation');
      return;
    }

    if (_isDisposed) return;

    _marginPercentage = margin;
    _recalculateMenu();
    _setError(null);
    _notifyListenersSafely();
  }

  // MENU COMPOSITION CRUD - FIXED: InputValidator compatibility
  Future<void> addIngredient(String namaIngredient, double jumlahDipakai,
      String satuan, double hargaPerSatuan) async {
    // FIXED: Validate inputs with correct method signatures
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

    // FIXED: Enhanced validation for unit prices with proper bounds checking
    if (!hargaPerSatuan.isFinite || hargaPerSatuan.isNaN) {
      _setError('Harga per satuan tidak valid');
      return;
    }

    if (hargaPerSatuan <= 0) {
      _setError('Harga per satuan harus lebih dari 0');
      return;
    }

    if (hargaPerSatuan > AppConstants.maxPrice) {
      _setError(
          'Harga per satuan terlalu mahal (maksimal ${AppConstants.maxPrice.toInt()})');
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

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final newComposition = MenuComposition(
          namaIngredient: namaIngredient.trim(),
          jumlahDipakai: jumlahDipakai,
          satuan: satuan,
          hargaPerSatuan: hargaPerSatuan,
        );

        // CRITICAL FIX: Create new list to avoid mutation
        _komposisiMenu = [..._komposisiMenu, newComposition];

        if (!_isDisposed) {
          _recalculateMenu();
          _setError(null);
          _notifyListenersSafely();
          debugPrint('✅ Ingredient added to menu: $namaIngredient');
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error adding ingredient: ${e.toString()}');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  Future<void> removeIngredient(int index) async {
    if (index < 0 || index >= _komposisiMenu.length) {
      _setError('Index ingredient tidak valid');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final removedName = _komposisiMenu[index].namaIngredient;

        // CRITICAL FIX: Safe list manipulation
        final newKomposisi = [..._komposisiMenu];
        if (index < newKomposisi.length) {
          newKomposisi.removeAt(index);
          _komposisiMenu = newKomposisi;

          if (!_isDisposed) {
            _recalculateMenu();
            _setError(null);
            _notifyListenersSafely();
            debugPrint('✅ Ingredient removed: $removedName');
          }
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error removing ingredient: ${e.toString()}');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // MENU MANAGEMENT - CRITICAL FIX: Async safety
  Future<void> saveCurrentMenu() async {
    if (_namaMenu.trim().isEmpty) {
      _setError('Nama menu tidak boleh kosong');
      return;
    }

    if (_komposisiMenu.isEmpty) {
      _setError('Komposisi menu tidak boleh kosong');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final menuItem = MenuItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          namaMenu: _namaMenu.trim(),
          komposisi: _komposisiMenu,
          createdAt: DateTime.now(),
        );

        await StorageService.saveMenuToHistory(menuItem);

        if (!_isDisposed) {
          _menuHistory = [menuItem, ..._menuHistory];

          // Clear current menu for new entry
          _namaMenu = '';
          _komposisiMenu = [];
          _lastCalculationResult = null;
          _setError(null);
          _notifyListenersSafely();

          debugPrint('✅ Menu saved to history: ${menuItem.namaMenu}');
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error saving menu: ${e.toString()}');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  void resetCurrentMenu() {
    if (_isDisposed) return;

    _namaMenu = '';
    _komposisiMenu = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
    _errorMessage = null;
    _notifyListenersSafely();
  }

  // CORE CALCULATION - CRITICAL FIX: Safe calculation with disposal check
  void _recalculateMenu() {
    if (_isDisposed) return;

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

      if (!_isDisposed) {
        _lastCalculationResult = MenuCalculatorService.calculateMenuCost(
          menu: menuItem,
          sharedData: _combinedData,
          marginPercentage: _marginPercentage,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Menu calculation error: $e');
        _lastCalculationResult = null;
      }
    }
  }

  // ANALYSIS METHODS - CRITICAL FIX: Disposal safety
  Map<String, dynamic> getMenuAnalysis() {
    if (_isDisposed ||
        _lastCalculationResult == null ||
        !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data menu belum lengkap untuk analisis',
      };
    }

    return MenuCalculatorService.analyzeMenuMargin(_lastCalculationResult!);
  }

  // VALIDATION METHODS
  bool get isMenuValid {
    if (_isDisposed) return false;
    return _namaMenu.trim().isNotEmpty &&
        _komposisiMenu.isNotEmpty &&
        MenuCalculatorService.isMenuCompositionValid(_komposisiMenu);
  }

  String? validateCurrentMenu() {
    if (_isDisposed) return 'Menu provider is disposed';

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

  // HELPER METHODS - CRITICAL FIX: Disposal safety
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    if (loading) _notifyListenersSafely();
  }

  void _setError(String? error) {
    if (_isDisposed) return;
    _errorMessage = error;
    _notifyListenersSafely();
  }

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    _notifyListenersSafely();
  }

  void resetAllData() {
    if (_isDisposed) return;

    _namaMenu = '';
    _komposisiMenu = [];
    _menuHistory = [];
    _marginPercentage = AppConstants.defaultMargin;
    _lastCalculationResult = null;
    _errorMessage = null;
    _notifyListenersSafely();
  }

  // UTILITY GETTERS - CRITICAL FIX: Disposal safety
  double get totalBahanBakuMenu {
    if (_isDisposed) return 0.0;
    return _komposisiMenu.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  String get formattedTotalBahanBaku {
    return MenuCalculatorService.formatRupiah(totalBahanBakuMenu);
  }

  String get formattedHargaJual {
    if (_isDisposed ||
        _lastCalculationResult == null ||
        !_lastCalculationResult!.isValid) {
      return MenuCalculatorService.formatRupiah(0);
    }
    return MenuCalculatorService.formatRupiah(
        _lastCalculationResult!.hargaSetelahMargin);
  }

  String get formattedProfit {
    if (_isDisposed ||
        _lastCalculationResult == null ||
        !_lastCalculationResult!.isValid) {
      return MenuCalculatorService.formatRupiah(0);
    }
    return MenuCalculatorService.formatRupiah(
        _lastCalculationResult!.profitPerMenu);
  }

  bool get hasIngredients => !_isDisposed && _komposisiMenu.isNotEmpty;
  bool get hasMenuHistory => !_isDisposed && _menuHistory.isNotEmpty;
  bool get isCalculationReady =>
      !_isDisposed &&
      _combinedData.isValidForCalculation &&
      _komposisiMenu.isNotEmpty &&
      _namaMenu.trim().isNotEmpty;
  int get ingredientCount => _isDisposed ? 0 : _komposisiMenu.length;
  int get historyCount => _isDisposed ? 0 : _menuHistory.length;

  @override
  void dispose() {
    _isDisposed = true; // CRITICAL FIX: Mark as disposed first
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _updateDebounceTimer?.cancel(); // CRITICAL FIX: Cancel debounce timer
    _updateDebounceTimer = null;
    super.dispose();
  }
}
