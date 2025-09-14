// lib/services/data_sync_controller.dart - PHASE 1: COMPLETE IMPLEMENTATION
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../providers/hpp_provider.dart';
import '../providers/operational_provider.dart';
import '../providers/menu_provider.dart';

/// PHASE 1: Complete implementation to make app runnable
/// This is a temporary solution until architectural refactoring in Phase 2
class DataSyncController {
  // Provider references
  HPPProvider? _hppProvider;
  OperationalProvider? _operationalProvider;
  MenuProvider? _menuProvider;

  // State flags
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Getters for checking state
  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;

  /// Initialize the sync controller with provider references
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

      // Perform initial sync
      _performInitialSync();
    } catch (e) {
      debugPrint('❌ DataSyncController: Initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Handle HPP data changes
  void onHppDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: HPP data changed, syncing...');

      // Sync HPP data to operational provider with null safety
      if (_hppProvider?.data != null && _operationalProvider != null) {
        _operationalProvider!.updateSharedData(_hppProvider!.data);
      }

      // Sync HPP data to menu provider with null safety
      if (_hppProvider?.data != null && _menuProvider != null) {
        _menuProvider!.updateSharedData(_hppProvider!.data);
      }

      debugPrint('✅ DataSyncController: HPP sync completed');
    } catch (e) {
      debugPrint('❌ DataSyncController: HPP sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Handle operational data changes
  void onOperationalDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Operational data changed, syncing...');

      // Sync operational data to menu provider
      if (_operationalProvider != null && _menuProvider != null) {
        final sharedData = _operationalProvider!.sharedData;
        if (sharedData != null) {
          _menuProvider!.updateSharedData(sharedData);
        }
      }

      debugPrint('✅ DataSyncController: Operational sync completed');
    } catch (e) {
      debugPrint('❌ DataSyncController: Operational sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Handle menu data changes
  void onMenuDataChanged() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Menu data changed');
      // Menu provider doesn't need to sync back to others
      // This is mainly for logging and potential future features
      debugPrint('✅ DataSyncController: Menu data change acknowledged');
    } catch (e) {
      debugPrint('❌ DataSyncController: Menu sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Sync data when switching tabs
  void syncOnTabSwitch() {
    if (!_isInitialized || _isDisposed) {
      debugPrint(
          '⚠️ DataSyncController: Cannot sync on tab switch - not initialized or disposed');
      return;
    }

    try {
      debugPrint('🔄 DataSyncController: Tab switch sync started');

      // Perform a full sync cycle
      _performFullSync();

      debugPrint('✅ DataSyncController: Tab switch sync completed');
    } catch (e) {
      debugPrint('❌ DataSyncController: Tab switch sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Force a full sync of all providers
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
    } catch (e) {
      debugPrint('❌ DataSyncController: Force full sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Perform initial sync when controller is initialized
  void _performInitialSync() {
    try {
      debugPrint('🚀 DataSyncController: Performing initial sync...');

      // Wait a frame to ensure providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performFullSync();
      });
    } catch (e) {
      debugPrint('❌ DataSyncController: Initial sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Perform full synchronization of all providers
  void _performFullSync() {
    try {
      // Sync HPP → Operational with enhanced null safety
      if (_hppProvider?.data != null && _operationalProvider != null) {
        _operationalProvider!.updateSharedData(_hppProvider!.data);
      }

      // Sync Operational → Menu (or HPP → Menu if operational is empty)
      if (_menuProvider != null) {
        if (_operationalProvider?.sharedData != null) {
          _menuProvider!.updateSharedData(_operationalProvider!.sharedData!);
        } else if (_hppProvider?.data != null) {
          _menuProvider!.updateSharedData(_hppProvider!.data);
        }
      }

      debugPrint('✅ DataSyncController: Full sync completed successfully');
    } catch (e) {
      debugPrint('❌ DataSyncController: Full sync failed: $e');
      // Don't rethrow - keep app running
    }
  }

  /// Check if all providers are properly connected
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

  /// Get sync status information
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

  /// Print detailed debug information
  void printDebugInfo() {
    final status = getSyncStatus();
    debugPrint('📊 DataSyncController Debug Info:');
    status.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }

  /// Dispose the controller and clean up resources
  void dispose() {
    if (_isDisposed) {
      debugPrint('⚠️ DataSyncController: Already disposed');
      return;
    }

    try {
      debugPrint('🗑️ DataSyncController: Disposing...');

      // Clear provider references
      _hppProvider = null;
      _operationalProvider = null;
      _menuProvider = null;

      // Mark as disposed
      _isDisposed = true;
      _isInitialized = false;

      debugPrint('✅ DataSyncController: Disposed successfully');
    } catch (e) {
      debugPrint('❌ DataSyncController: Disposal failed: $e');
      // Force disposal even if there's an error
      _isDisposed = true;
      _isInitialized = false;
    }
  }

  /// Reset the controller (useful for testing or reinitialization)
  void reset() {
    try {
      debugPrint('🔄 DataSyncController: Resetting...');

      dispose();

      // Reset state
      _isDisposed = false;
      _isInitialized = false;

      debugPrint('✅ DataSyncController: Reset completed');
    } catch (e) {
      debugPrint('❌ DataSyncController: Reset failed: $e');
      // Force reset even if there's an error
      _isDisposed = false;
      _isInitialized = false;
    }
  }

  /// Get provider data for debugging
  Map<String, dynamic> getProviderData() {
    return {
      'hpp': {
        'isAvailable': _hppProvider != null,
        'dataItems': _hppProvider?.data.totalItemCount ?? 0,
        'isCalculationReady': _hppProvider?.isCalculationReady ?? false,
      },
      'operational': {
        'isAvailable': _operationalProvider != null,
        'karyawanCount': _operationalProvider?.karyawanCount ?? 0,
        'hasSharedData': _operationalProvider?.sharedData != null,
      },
      'menu': {
        'isAvailable': _menuProvider != null,
        'ingredientCount': _menuProvider?.ingredientCount ?? 0,
        'historyCount': _menuProvider?.historyCount ?? 0,
        'isCalculationReady': _menuProvider?.isCalculationReady ?? false,
      },
    };
  }

  /// Emergency sync method - use with caution
  void emergencySync() {
    debugPrint('🚨 DataSyncController: EMERGENCY SYNC INITIATED');

    try {
      // Force sync regardless of state
      if (_hppProvider != null && _operationalProvider != null) {
        _operationalProvider!.updateSharedData(_hppProvider!.data);
        debugPrint('🚨 Emergency: HPP → Operational sync done');
      }

      if (_operationalProvider != null && _menuProvider != null) {
        final sharedData = _operationalProvider!.sharedData;
        if (sharedData != null) {
          _menuProvider!.updateSharedData(sharedData);
          debugPrint('🚨 Emergency: Operational → Menu sync done');
        }
      }

      debugPrint('🚨 DataSyncController: EMERGENCY SYNC COMPLETED');
    } catch (e) {
      debugPrint('🚨 DataSyncController: EMERGENCY SYNC FAILED: $e');
    }
  }
}
