// lib/providers/hpp_provider.dart - CRITICAL FIX: Race Condition + Async State Safety
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/shared_calculation_data.dart';
import '../services/hpp_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

class HPPProvider with ChangeNotifier {
  SharedCalculationData _data = SharedCalculationData();
  String? _errorMessage;
  bool _isLoading = false;
  HPPCalculationResult? _lastCalculationResult;
  Timer? _autoSaveTimer;

  // CRITICAL FIX: Enhanced async safety + operation queue
  int _dataVersion = 0;
  bool _isDisposed = false;
  bool _isUpdating = false;

  // CRITICAL FIX: Operation queue to prevent race conditions
  final List<Future<void> Function()> _operationQueue = [];
  bool _isProcessingQueue = false;
  Completer<void>? _currentOperation;

  // Getters
  SharedCalculationData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  HPPCalculationResult? get lastCalculationResult => _lastCalculationResult;
  int get dataVersion => _dataVersion;

  // CRITICAL FIX: Safe async operation with queue system
  Future<T?> _safeAsyncOperation<T>(Future<T> Function() operation) async {
    if (_isDisposed) return null;

    // CRITICAL FIX: Create completer for this operation
    final completer = Completer<T?>();

    // CRITICAL FIX: Add to queue to prevent race conditions
    _operationQueue.add(() async {
      if (_isDisposed) {
        completer.complete(null);
        return;
      }

      _isUpdating = true;
      _currentOperation = Completer<void>();

      try {
        final result = await operation();
        if (_isDisposed) {
          completer.complete(null);
        } else {
          completer.complete(result);
        }
      } catch (e) {
        if (!_isDisposed) {
          debugPrint('❌ HPP Operation error: $e');
          completer.completeError(e);
        } else {
          completer.complete(null);
        }
      } finally {
        if (!_isDisposed) {
          _isUpdating = false;
          _currentOperation?.complete();
          _currentOperation = null;
        }
      }
    });

    // CRITICAL FIX: Process queue if not already processing
    _processOperationQueue();

    return completer.future;
  }

  // CRITICAL FIX: Queue processor to handle operations sequentially
  Future<void> _processOperationQueue() async {
    if (_isProcessingQueue || _operationQueue.isEmpty || _isDisposed) {
      return;
    }

    _isProcessingQueue = true;

    while (_operationQueue.isNotEmpty && !_isDisposed) {
      final operation = _operationQueue.removeAt(0);

      try {
        await operation();

        // CRITICAL FIX: Wait for current operation to complete
        if (_currentOperation != null) {
          await _currentOperation!.future;
        }

        // CRITICAL FIX: Small delay to prevent overwhelming
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint('❌ Queue operation error: $e');
        // Continue processing other operations
      }
    }

    _isProcessingQueue = false;
  }

  // CRITICAL FIX: Safe state update with version increment
  void _updateDataSafely(SharedCalculationData newData) {
    if (_isDisposed) return;

    _data = newData;
    _dataVersion++; // CRITICAL FIX: Increment version for anti-loop
    _recalculateHPP();
  }

  // CRITICAL FIX: Safe notification with disposal check
  void _notifyListenersSafely() {
    if (_isDisposed || _isUpdating) return;

    // CRITICAL FIX: Use microtask to prevent immediate recursion
    scheduleMicrotask(() {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  // INITIALIZATION
  Future<void> initializeFromStorage() async {
    final result = await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        final savedData = await StorageService.loadSharedData();
        if (savedData != null && !_isDisposed) {
          _updateDataSafely(savedData);
          debugPrint('✅ HPP Data loaded: ${savedData.totalItemCount} items');
        }
        _setError(null);
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error loading data: ${e.toString()}');
          debugPrint('❌ Error loading HPP: $e');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });

    if (result == null && !_isDisposed) {
      _setLoading(false);
    }
  }

  // VARIABLE COSTS METHODS - CRITICAL FIX: Queue-based async safety
  Future<void> addVariableCost(
      String nama, double totalHarga, double jumlah, String satuan) async {
    // CRITICAL FIX: Input validation before async operation
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _setError('Nama: $namaValidation');
      return;
    }

    final hargaValidation = InputValidator.validatePrice(totalHarga.toString());
    if (hargaValidation != null) {
      _setError('Harga: $hargaValidation');
      return;
    }

    final jumlahValidation = InputValidator.validateQuantity(jumlah.toString());
    if (jumlahValidation != null) {
      _setError('Jumlah: $jumlahValidation');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        // CRITICAL FIX: Create new list to avoid mutation during async
        final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
        newCosts.add({
          'nama': nama.trim(),
          'totalHarga': totalHarga,
          'jumlah': jumlah,
          'satuan': satuan,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (!_isDisposed) {
          _updateDataSafely(_data.copyWith(variableCosts: newCosts));
          _setError(null);
          _scheduleAutoSave();
          _notifyListenersSafely();
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError(e.toString());
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  Future<void> removeVariableCost(int index) async {
    if (index < 0 || index >= _data.variableCosts.length) return;

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        // CRITICAL FIX: Safe list manipulation
        final newCosts = List<Map<String, dynamic>>.from(_data.variableCosts);
        if (index < newCosts.length) {
          newCosts.removeAt(index);

          if (!_isDisposed) {
            _updateDataSafely(_data.copyWith(variableCosts: newCosts));
            _setError(null);
            _scheduleAutoSave();
            _notifyListenersSafely();
          }
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError(e.toString());
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // FIXED COSTS METHODS - CRITICAL FIX: Same queue-based pattern
  Future<void> addFixedCost(String jenis, double nominal) async {
    final jenisValidation = InputValidator.validateName(jenis);
    if (jenisValidation != null) {
      _setError('Jenis: $jenisValidation');
      return;
    }

    final nominalValidation = InputValidator.validatePrice(nominal.toString());
    if (nominalValidation != null) {
      _setError('Nominal: $nominalValidation');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final newCosts = List<Map<String, dynamic>>.from(_data.fixedCosts);
        newCosts.add({
          'jenis': jenis.trim(),
          'nominal': nominal,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (!_isDisposed) {
          _updateDataSafely(_data.copyWith(fixedCosts: newCosts));
          _setError(null);
          _scheduleAutoSave();
          _notifyListenersSafely();
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError(e.toString());
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  Future<void> removeFixedCost(int index) async {
    if (index < 0 || index >= _data.fixedCosts.length) return;

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final newCosts = List<Map<String, dynamic>>.from(_data.fixedCosts);
        if (index < newCosts.length) {
          newCosts.removeAt(index);

          if (!_isDisposed) {
            _updateDataSafely(_data.copyWith(fixedCosts: newCosts));
            _setError(null);
            _scheduleAutoSave();
            _notifyListenersSafely();
          }
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError(e.toString());
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // ESTIMATION METHODS - CRITICAL FIX: Queue-based async safety
  Future<void> updateEstimasi(double porsi, double produksiBulanan) async {
    final porsiValidation = InputValidator.validateQuantity(porsi.toString());
    if (porsiValidation != null) {
      _setError('Estimasi Porsi: $porsiValidation');
      return;
    }

    final produksiValidation =
        InputValidator.validateQuantity(produksiBulanan.toString());
    if (produksiValidation != null) {
      _setError('Estimasi Produksi: $produksiValidation');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        if (!_isDisposed) {
          _updateDataSafely(_data.copyWith(
            estimasiPorsi: porsi,
            estimasiProduksiBulanan: produksiBulanan,
          ));
          _setError(null);
          _scheduleAutoSave();
          _notifyListenersSafely();
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError(e.toString());
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // CORE CALCULATION - CRITICAL FIX: Safe calculation
  void _recalculateHPP() {
    if (_isDisposed) return;

    try {
      final result = HPPCalculatorService.calculateHPP(
        variableCosts: _data.variableCosts,
        fixedCosts: _data.fixedCosts,
        estimasiPorsiPerProduksi: _data.estimasiPorsi,
        estimasiProduksiBulanan: _data.estimasiProduksiBulanan,
      );

      if (_isDisposed) return;

      _lastCalculationResult = result;

      if (result.isValid && !_isDisposed) {
        _data = _data.copyWith(
          hppMurniPerPorsi: result.hppMurniPerPorsi,
          biayaVariablePerPorsi: result.biayaVariablePerPorsi,
          biayaFixedPerPorsi: result.biayaFixedPerPorsi,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        _lastCalculationResult = null;
        debugPrint('❌ HPP Calculation error: $e');
      }
    }
  }

  // AUTO-SAVE - CRITICAL FIX: Queue-aware auto-save
  void _scheduleAutoSave() {
    if (_isDisposed) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed && !_isProcessingQueue) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (_isDisposed) return;

    try {
      await StorageService.autoSave(_data);
      if (!_isDisposed) {
        debugPrint('💾 HPP Auto-save completed');
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ HPP Auto-save failed: $e');
      }
    }
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

  void resetData() {
    if (_isDisposed) return;
    _data = SharedCalculationData();
    _lastCalculationResult = null;
    _errorMessage = null;
    _isLoading = false;
    _dataVersion++; // CRITICAL FIX: Increment version
    _scheduleAutoSave();
    _notifyListenersSafely();
  }

  // UTILITY GETTERS
  String get formattedTotalVariableCosts {
    return _data.formatRupiah(_data.totalVariableCosts);
  }

  String get formattedTotalFixedCosts {
    return _data.formatRupiah(_data.totalFixedCosts);
  }

  String get formattedHppMurni {
    return _data.formatRupiah(_data.hppMurniPerPorsi);
  }

  bool get isCalculationReady {
    return _data.variableCosts.isNotEmpty &&
        _data.estimasiPorsi > 0 &&
        _data.estimasiProduksiBulanan > 0;
  }

  @override
  void dispose() {
    _isDisposed = true; // CRITICAL FIX: Mark as disposed first

    // CRITICAL FIX: Cancel all pending operations
    _operationQueue.clear();
    _currentOperation?.complete();
    _currentOperation = null;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    super.dispose();
  }
}
