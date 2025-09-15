// lib/providers/operational_provider.dart - CRITICAL FIX: Memory-Safe Instance-based Tracking
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/karyawan_data.dart';
import '../models/shared_calculation_data.dart';
import '../services/operational_calculator_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class OperationalProvider with ChangeNotifier {
  List<KaryawanData> _karyawan = [];
  String? _errorMessage;
  bool _isLoading = false;
  OperationalCalculationResult? _lastCalculationResult;
  Timer? _autoSaveTimer;

  // CRITICAL FIX: Enhanced async safety + operation queue
  SharedCalculationData _hppData = SharedCalculationData();
  int _dataVersion = 0;
  int _lastHppVersion = -1;
  bool _isDisposed = false;
  bool _isUpdating = false;

  // CRITICAL FIX: Instance-based tracking (replaces mixin)
  DateTime? _lastUpdateTime;
  DateTime? _lastResetTime;
  int _updateCount = 0;

  // CRITICAL FIX: Operation queue to prevent race conditions
  final List<Future<void> Function()> _operationQueue = [];
  bool _isProcessingQueue = false;
  Completer<void>? _currentOperation;

  // Getters
  List<KaryawanData> get karyawan => _karyawan;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  OperationalCalculationResult? get lastCalculationResult =>
      _lastCalculationResult;
  SharedCalculationData get hppData => _hppData;
  int get dataVersion => _dataVersion;
  int get lastHppVersion => _lastHppVersion;

  // CRITICAL FIX: Instance-based tracking methods
  bool _hasRecentUpdate(DateTime now) {
    if (_lastUpdateTime == null) return false;
    return now.difference(_lastUpdateTime!).inMilliseconds < 300;
  }

  bool _shouldCircuitBreak(DateTime now) {
    if (_updateCount <= 30) return false;

    if (_lastResetTime == null ||
        now.difference(_lastResetTime!).inSeconds >= 10) {
      _updateCount = 0;
      _lastResetTime = now;
      return false;
    }

    return true;
  }

  void _recordUpdate(DateTime now) {
    _lastUpdateTime = now;
    _updateCount++;
  }

  void _disposeTracking() {
    _lastUpdateTime = null;
    _lastResetTime = null;
    _updateCount = 0;
  }

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
          debugPrint('❌ Operational Operation error: $e');
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
        debugPrint('❌ Operational Queue operation error: $e');
        // Continue processing other operations
      }
    }

    _isProcessingQueue = false;
  }

  // CRITICAL FIX: Safe notification with disposal check
// NEW CODE (FIXED):
  void _notifyListenersSafely() {
    if (_isDisposed || _isUpdating) return;

    // DIRECT CALL - no more scheduleMicrotask
    notifyListeners();
  }

  // INITIALIZATION
  Future<void> initializeFromStorage() async {
    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        final savedData = await StorageService.loadSharedData();
        if (savedData != null && !_isDisposed) {
          _karyawan = savedData.karyawan;
          print('🔧 LOADED from storage: ${_karyawan.length} karyawan');
          print('🔧 LOADED savedData.karyawan: ${savedData.karyawan.length}');
          _dataVersion++;
          debugPrint('✅ Operational Data loaded: ${_karyawan.length} karyawan');
        }
        _setError(null);
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error loading operational data: ${e.toString()}');
          debugPrint('❌ Error loading operational: $e');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // CRITICAL FIX: Anti-loop HPP update mechanism with instance-based tracking
  void updateFromHPP(SharedCalculationData hppData, int hppVersion) {
    if (_isDisposed || _isUpdating || _isProcessingQueue) return;

    // CRITICAL FIX: Only update if HPP version actually changed
    if (_lastHppVersion == hppVersion) {
      return; // Prevent loop - already processed this version
    }

    // CRITICAL FIX: Use instance-based rate limiting
    final now = DateTime.now();
    if (_hasRecentUpdate(now)) {
      debugPrint(
          '⚠️ Rate limiting: HPP→Operational update throttled (instance-based)');
      return;
    }

    if (_shouldCircuitBreak(now)) {
      debugPrint(
          '⚠️ CIRCUIT BREAKER: Too many HPP→Operational updates, pausing (instance-based)');
      return;
    }

    // CRITICAL FIX: Add HPP update to queue to prevent race with other operations
    _operationQueue.add(() async {
      if (_isDisposed) return;

      try {
        _isUpdating = true;

        // Update reference data but keep our karyawan list
        final oldHppData = _hppData;
        _hppData = oldHppData.copyWith(
            karyawan: List.from(_karyawan)); // ← CHANGE THIS LINE
        print(
            '🔧 Provider: Updated hppData, karyawan count: ${_hppData.karyawan.length}');
        print(
            '🔧 Same object? ${identical(oldHppData, _hppData)}'); // ← ADD THIS
        _lastHppVersion = hppVersion;
        _dataVersion++;

        _recalculateOperational();
        _scheduleAutoSave();

        // CRITICAL FIX: Record update using instance-based tracking
        _recordUpdate(now);

        debugPrint(
            '✅ Operational updated from HPP version $hppVersion (instance-based tracking)');
      } catch (e) {
        if (!_isDisposed) {
          debugPrint('❌ Error updating from HPP: $e');
        }
      } finally {
        _isUpdating = false;
        if (!_isDisposed) {
          _notifyListenersSafely();
        }
      }
    });

    _processOperationQueue();
  }

  // KARYAWAN CRUD METHODS - CRITICAL FIX: Queue-based async safety
  Future<void> addKaryawan(String nama, String jabatan, double gaji) async {
    print('🔍 Provider: addKaryawan called with $nama');
    // CRITICAL FIX: Validate inputs before async operation
    final namaValidation = InputValidator.validateName(nama);
    if (namaValidation != null) {
      _setError('Nama karyawan: $namaValidation');
      return;
    }

    final jabatanValidation = InputValidator.validateName(jabatan);
    if (jabatanValidation != null) {
      _setError('Jabatan: $jabatanValidation');
      return;
    }

    final salaryValidation = InputValidator.validateSalaryDirect(gaji);
    if (salaryValidation != null) {
      _setError('Gaji: $salaryValidation');
      return;
    }

    if (gaji < AppConstants.minSalary) {
      _setError(
          'Gaji terlalu rendah (minimal ${AppFormatters.formatRupiah(AppConstants.minSalary)})');
      return;
    }

    // Check for duplicates
    bool isDuplicate = _karyawan.any((k) =>
        k.namaKaryawan.toLowerCase().trim() == nama.toLowerCase().trim());

    if (isDuplicate) {
      _setError('Nama karyawan sudah ada. Gunakan nama yang berbeda.');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final newKaryawan = KaryawanData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          namaKaryawan: nama.trim(),
          jabatan: jabatan.trim(),
          gajiBulanan: gaji,
          createdAt: DateTime.now(),
        );

        // CRITICAL FIX: Create new list to avoid mutation during async
        _karyawan = [..._karyawan, newKaryawan];

        if (!_isDisposed) {
          // Update combined data and recalculate
          _hppData = _hppData.copyWith(karyawan: _karyawan);
          print('🔧 After sync - _karyawan: ${_karyawan.length}');
          print(
              '🔧 After sync - _hppData.karyawan: ${_hppData.karyawan.length}');
          print(
              '🔍 Provider: Updated hppData, karyawan count: ${_hppData.karyawan.length}');
          _dataVersion++;
          _recalculateOperational();
          _setError(null);
          _scheduleAutoSave();
          _notifyListenersSafely();

          debugPrint('✅ Karyawan added: $nama');
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error adding karyawan: ${e.toString()}');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  Future<void> removeKaryawan(int index) async {
    if (index < 0 || index >= _karyawan.length) {
      _setError('Index karyawan tidak valid');
      return;
    }

    await _safeAsyncOperation(() async {
      _setLoading(true);
      try {
        if (_isDisposed) return false;

        final removedName = _karyawan[index].namaKaryawan;

        // CRITICAL FIX: Safe list manipulation
        final newKaryawan = [..._karyawan];
        if (index < newKaryawan.length) {
          newKaryawan.removeAt(index);
          _karyawan = newKaryawan;

          if (!_isDisposed) {
            // Update combined data and recalculate
            _hppData = _hppData.copyWith(karyawan: _karyawan);
            _dataVersion++;
            _recalculateOperational();
            _setError(null);
            _scheduleAutoSave();
            _notifyListenersSafely();

            debugPrint('✅ Karyawan removed: $removedName');
          }
        }
        return true;
      } catch (e) {
        if (!_isDisposed) {
          _setError('Error removing karyawan: ${e.toString()}');
        }
        return false;
      } finally {
        if (!_isDisposed) {
          _setLoading(false);
        }
      }
    });
  }

  // CORE CALCULATION - CRITICAL FIX: Safe calculation with disposal check
  void _recalculateOperational() {
    if (_isDisposed) return;

    try {
      // CRITICAL FIX: Division by zero protection
      double estimasiPorsi = _hppData.estimasiPorsi;
      double estimasiProduksi = _hppData.estimasiProduksiBulanan;
      double hppMurni = _hppData.hppMurniPerPorsi;

      if (estimasiPorsi <= 0 || estimasiProduksi <= 0) {
        debugPrint('⚠️ Invalid estimation values, skipping calculation');
        _lastCalculationResult = null;
        return;
      }

      final result = OperationalCalculatorService.calculateOperationalCost(
        karyawan: _karyawan,
        hppMurniPerPorsi: hppMurni,
        estimasiPorsiPerProduksi: estimasiPorsi,
        estimasiProduksiBulanan: estimasiProduksi,
      );

      if (_isDisposed) return;

      _lastCalculationResult = result;

      if (result.isValid && !_isDisposed) {
        // Update our combined data with calculation results
        _hppData = _hppData.copyWith(
          karyawan: _karyawan,
          totalOperationalCost: result.totalGajiBulanan,
          totalHargaSetelahOperational: result.totalHargaSetelahOperational,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        _lastCalculationResult = null;
        debugPrint('❌ Operational calculation error: $e');
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
      await StorageService.autoSave(_hppData);
      if (!_isDisposed) {
        debugPrint('💾 Operational Auto-save completed');
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Operational Auto-save failed: $e');
      }
    }
  }

  // ANALYSIS METHODS - CRITICAL FIX: Disposal safety
  Map<String, dynamic> getEfficiencyAnalysis() {
    if (_isDisposed ||
        _lastCalculationResult == null ||
        !_lastCalculationResult!.isValid) {
      return {
        'isAvailable': false,
        'message': 'Data belum lengkap untuk analisis',
      };
    }

    return OperationalCalculatorService.analyzeKaryawanEfficiency(
      karyawan: _karyawan,
      totalPorsiBulanan: _lastCalculationResult!.totalPorsiBulanan,
    );
  }

  Map<String, dynamic> getProjectionAnalysis() {
    if (_isDisposed ||
        _hppData.estimasiPorsi <= 0 ||
        _hppData.estimasiProduksiBulanan <= 0) {
      return {
        'isAvailable': false,
        'message': 'Data belum tersedia untuk proyeksi',
      };
    }

    return OperationalCalculatorService.calculateOperationalProjection(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _hppData.estimasiPorsi,
      estimasiProduksiBulanan: _hppData.estimasiProduksiBulanan,
    );
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

    _karyawan = [];
    _lastCalculationResult = null;
    _errorMessage = null;
    _isLoading = false;
    _dataVersion++;

    // Update combined data
    _hppData = _hppData.copyWith(
      karyawan: _karyawan,
      totalOperationalCost: 0.0,
      totalHargaSetelahOperational: _hppData.hppMurniPerPorsi,
    );

    _scheduleAutoSave();
    _notifyListenersSafely();
  }

  // UTILITY GETTERS - CRITICAL FIX: Disposal safety
  double get totalGajiBulanan {
    if (_isDisposed) return 0.0;
    return OperationalCalculatorService.calculateTotalGajiBulanan(_karyawan);
  }

  double get operationalCostPerPorsi {
    if (_isDisposed ||
        _hppData.estimasiPorsi <= 0 ||
        _hppData.estimasiProduksiBulanan <= 0) {
      return 0.0;
    }

    return OperationalCalculatorService.calculateOperationalCostPerPorsi(
      karyawan: _karyawan,
      estimasiPorsiPerProduksi: _hppData.estimasiPorsi,
      estimasiProduksiBulanan: _hppData.estimasiProduksiBulanan,
    );
  }

  String get formattedTotalGaji {
    return OperationalCalculatorService.formatRupiah(totalGajiBulanan);
  }

  String get formattedOperationalPerPorsi {
    return OperationalCalculatorService.formatRupiah(operationalCostPerPorsi);
  }

  bool get hasKaryawan => _karyawan.isNotEmpty;
  bool get isCalculationReady =>
      _karyawan.isNotEmpty && _hppData.isValidForCalculation;
  int get karyawanCount => _karyawan.length;

  @override
  void dispose() {
    _isDisposed = true; // CRITICAL FIX: Mark as disposed first

    // CRITICAL FIX: Cancel all pending operations
    _operationQueue.clear();
    _currentOperation?.complete();
    _currentOperation = null;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    // CRITICAL FIX: Dispose instance-based tracking
    _disposeTracking();

    super.dispose();
  }
}
