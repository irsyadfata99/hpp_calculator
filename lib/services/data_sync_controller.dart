// lib/services/data_sync_controller.dart - DIAGNOSTIC VERSION
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../providers/hpp_provider.dart';
import '../providers/operational_provider.dart';
import '../providers/menu_provider.dart';
import '../models/shared_calculation_data.dart';

class DataSyncController {
  // Provider references
  HPPProvider? _hppProvider;
  OperationalProvider? _operationalProvider;
  MenuProvider? _menuProvider;

  // State flags
  bool _isInitialized = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;

  void initialize({
    required HPPProvider hppProvider,
    required OperationalProvider operationalProvider,
    required MenuProvider menuProvider,
  }) {
    if (_isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot initialize disposed controller');
      return;
    }

    try {
      _hppProvider = hppProvider;
      _operationalProvider = operationalProvider;
      _menuProvider = menuProvider;
      _isInitialized = true;

      debugPrint('✅ DataSyncController: Initialized successfully');
      debugPrint('📊 Provider validation:');
      debugPrint('  HPP Provider: ${_hppProvider != null ? "OK" : "NULL"}');
      debugPrint(
          '  Operational Provider: ${_operationalProvider != null ? "OK" : "NULL"}');
      debugPrint('  Menu Provider: ${_menuProvider != null ? "OK" : "NULL"}');

      // Perform initial sync with enhanced debugging
      _performInitialSync();
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  void onHppDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: HPP data changed, syncing...');
      debugPrint('📊 HPP Data validation:');
      debugPrint('  HPP Provider exists: ${_hppProvider != null}');
      debugPrint('  HPP Data exists: ${_hppProvider?.data != null}');

      if (_hppProvider?.data != null) {
        debugPrint(
            '  Variable costs count: ${_hppProvider!.data.variableCosts.length}');
        debugPrint(
            '  Fixed costs count: ${_hppProvider!.data.fixedCosts.length}');
        debugPrint('  HPP murni: ${_hppProvider!.data.hppMurniPerPorsi}');
      }

      // Sync to operational
      if (_hppProvider?.data != null && _operationalProvider != null) {
        debugPrint('🔄 Syncing HPP → Operational...');
        _operationalProvider!.updateSharedData(_hppProvider!.data);
        debugPrint('✅ HPP → Operational sync completed');
      } else {
        debugPrint('❌ HPP → Operational sync failed: missing data or provider');
      }

      // Sync to menu
      if (_hppProvider?.data != null && _menuProvider != null) {
        debugPrint('🔄 Syncing HPP → Menu...');
        _menuProvider!.updateSharedData(_hppProvider!.data);
        debugPrint('✅ HPP → Menu sync completed');
      } else {
        debugPrint('❌ HPP → Menu sync failed: missing data or provider');
      }

      debugPrint('✅ DataSyncController: HPP sync completed');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: HPP sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void onOperationalDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Operational data changed, syncing...');

      if (_operationalProvider != null && _menuProvider != null) {
        final sharedData = _operationalProvider!.sharedData;
        debugPrint('📊 Operational Data validation:');
        debugPrint('  Shared data exists: ${sharedData != null}');

        if (sharedData != null) {
          debugPrint('  Karyawan count: ${sharedData.karyawan.length}');
          debugPrint(
              '  Total operational cost: ${sharedData.totalOperationalCost}');

          debugPrint('🔄 Syncing Operational → Menu...');
          _menuProvider!.updateSharedData(sharedData);
          debugPrint('✅ Operational → Menu sync completed');
        }
      }

      debugPrint('✅ DataSyncController: Operational sync completed');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Operational sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void onMenuDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Menu data changed');
      debugPrint('✅ DataSyncController: Menu data change acknowledged');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Menu sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void syncOnTabSwitch() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync on tab switch - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Tab switch sync started');
      _performFullSync();
      debugPrint('✅ DataSyncController: Tab switch sync completed');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Tab switch sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void forceFullSync() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot force sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Force full sync started');
      _performFullSync();
      debugPrint('✅ DataSyncController: Force full sync completed');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Force full sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _performInitialSync() {
    try {
      debugPrint('🚀 DataSyncController: Performing initial sync...');

      // Wait a frame to ensure providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          debugPrint('🔄 DataSyncController: Post-frame callback executing...');
          _performFullSync();
        } catch (e, stackTrace) {
          debugPrint('❌ DataSyncController: Post-frame sync failed: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Initial sync setup failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _performFullSync() {
    try {
      debugPrint('🔄 DataSyncController: Starting full sync...');

      // STEP 1: Validate all providers
      debugPrint('📊 Full sync validation:');
      debugPrint('  HPP Provider: ${_hppProvider != null}');
      debugPrint('  Operational Provider: ${_operationalProvider != null}');
      debugPrint('  Menu Provider: ${_menuProvider != null}');

      if (_hppProvider?.data != null) {
        debugPrint(
            '  HPP Data: variable=${_hppProvider!.data.variableCosts.length}, fixed=${_hppProvider!.data.fixedCosts.length}');
      }

      // STEP 2: Sync HPP → Operational
      if (_hppProvider?.data != null && _operationalProvider != null) {
        debugPrint('🔄 Step 1: HPP → Operational sync...');
        try {
          _operationalProvider!.updateSharedData(_hppProvider!.data);
          debugPrint('✅ Step 1: HPP → Operational sync SUCCESS');
        } catch (e) {
          debugPrint('❌ Step 1: HPP → Operational sync FAILED: $e');
          throw e;
        }
      } else {
        debugPrint(
            '⚠️ Step 1: HPP → Operational sync SKIPPED (missing data or provider)');
      }

      // STEP 3: Sync to Menu
      if (_menuProvider != null) {
        debugPrint('🔄 Step 2: Syncing to Menu...');
        try {
          SharedCalculationData? dataToSync;

          // Priority: Use operational data if available, fallback to HPP data
          if (_operationalProvider?.sharedData != null) {
            dataToSync = _operationalProvider!.sharedData!;
            debugPrint('  Using Operational data for Menu sync');
          } else if (_hppProvider?.data != null) {
            dataToSync = _hppProvider!.data;
            debugPrint('  Using HPP data for Menu sync (fallback)');
          }

          if (dataToSync != null) {
            _menuProvider!.updateSharedData(dataToSync);
            debugPrint('✅ Step 2: Menu sync SUCCESS');
          } else {
            debugPrint('⚠️ Step 2: Menu sync SKIPPED (no data available)');
          }
        } catch (e) {
          debugPrint('❌ Step 2: Menu sync FAILED: $e');
          throw e;
        }
      } else {
        debugPrint('⚠️ Step 2: Menu sync SKIPPED (no menu provider)');
      }

      debugPrint('✅ DataSyncController: Full sync completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ DataSyncController: Full sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - keep app running
    }
  }

  // Enhanced debugging methods
  void printDetailedDebugInfo() {
    debugPrint('🔍 DataSyncController Detailed Debug Info:');
    debugPrint('=' * 50);

    debugPrint('📊 Controller State:');
    debugPrint('  isInitialized: $_isInitialized');
    debugPrint('  isDisposed: $_isDisposed');

    debugPrint('📊 Provider Status:');
    debugPrint('  HPP Provider: ${_hppProvider != null ? "EXISTS" : "NULL"}');
    debugPrint(
        '  Operational Provider: ${_operationalProvider != null ? "EXISTS" : "NULL"}');
    debugPrint('  Menu Provider: ${_menuProvider != null ? "EXISTS" : "NULL"}');

    if (_hppProvider != null) {
      debugPrint('📊 HPP Provider Data:');
      debugPrint('  Data exists: ${_hppProvider!.data != null}');
      if (_hppProvider!.data != null) {
        debugPrint(
            '  Variable costs: ${_hppProvider!.data.variableCosts.length}');
        debugPrint('  Fixed costs: ${_hppProvider!.data.fixedCosts.length}');
        debugPrint('  HPP murni: ${_hppProvider!.data.hppMurniPerPorsi}');
        debugPrint('  Estimasi porsi: ${_hppProvider!.data.estimasiPorsi}');
        debugPrint(
            '  Estimasi produksi: ${_hppProvider!.data.estimasiProduksiBulanan}');
      }
    }

    if (_operationalProvider != null) {
      debugPrint('📊 Operational Provider Data:');
      debugPrint(
          '  Shared data exists: ${_operationalProvider!.sharedData != null}');
      debugPrint('  Karyawan count: ${_operationalProvider!.karyawan.length}');
    }

    if (_menuProvider != null) {
      debugPrint('📊 Menu Provider Data:');
      debugPrint(
          '  Available ingredients: ${_menuProvider!.availableIngredients.length}');
      debugPrint(
          '  Current menu ingredients: ${_menuProvider!.ingredientCount}');
      debugPrint('  Menu name: "${_menuProvider!.namaMenu}"');
    }

    debugPrint('=' * 50);
  }

  bool validateConnections() {
    if (!_isInitialized || _isDisposed) return false;

    bool isValid = _hppProvider != null &&
        _operationalProvider != null &&
        _menuProvider != null;

    if (!isValid) {
      debugPrint('⚠️ DataSyncController: Invalid connections detected');
      debugPrint('  HPP Provider: ${_hppProvider != null ? "OK" : "NULL"}');
      debugPrint(
          '  Operational Provider: ${_operationalProvider != null ? "OK" : "NULL"}');
      debugPrint('  Menu Provider: ${_menuProvider != null ? "OK" : "NULL"}');
    }

    return isValid;
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isDisposed': _isDisposed,
      'hasHppProvider': _hppProvider != null,
      'hasOperationalProvider': _operationalProvider != null,
      'hasMenuProvider': _menuProvider != null,
      'connectionsValid': validateConnections(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    if (_isDisposed) {
      debugPrint('⚠️ DataSyncController: Already disposed');
      return;
    }

    try {
      debugPrint('🗑️ DataSyncController: Disposing...');

      _hppProvider = null;
      _operationalProvider = null;
      _menuProvider = null;

      _isDisposed = true;
      _isInitialized = false;

      debugPrint('✅ DataSyncController: Disposed successfully');
    } catch (e) {
      debugPrint('❌ DataSyncController: Disposal failed: $e');
      _isDisposed = true;
      _isInitialized = false;
    }
  }

  void reset() {
    try {
      debugPrint('🔄 DataSyncController: Resetting...');
      dispose();
      _isDisposed = false;
      _isInitialized = false;
      debugPrint('✅ DataSyncController: Reset completed');
    } catch (e) {
      debugPrint('❌ DataSyncController: Reset failed: $e');
      _isDisposed = false;
      _isInitialized = false;
    }
  }

  // Emergency diagnostic method
  void emergencyDiagnostic() {
    debugPrint('🚨 DataSyncController: EMERGENCY DIAGNOSTIC');
    debugPrint('=' * 60);

    try {
      printDetailedDebugInfo();

      debugPrint('🔧 Attempting emergency sync...');
      if (_hppProvider != null && _menuProvider != null) {
        try {
          _menuProvider!.updateSharedData(_hppProvider!.data);
          debugPrint('🚨 Emergency HPP → Menu sync: SUCCESS');
        } catch (e) {
          debugPrint('🚨 Emergency HPP → Menu sync: FAILED - $e');
        }
      }

      debugPrint('🚨 DataSyncController: Emergency diagnostic completed');
    } catch (e) {
      debugPrint('🚨 DataSyncController: Emergency diagnostic failed: $e');
    }

    debugPrint('=' * 60);
  }
}
