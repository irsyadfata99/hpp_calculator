// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import '../models/shared_calculation_data.dart';
// import '../providers/hpp_provider.dart';
// import '../providers/operational_provider.dart';
// import '../providers/menu_provider.dart';
// import 'storage_service.dart';
// import 'hpp_calculator_service.dart';
// import 'operational_calculator_service.dart';

// class DataSyncService {
//   static Timer? _autoSaveTimer;

//   static Future<void> initializeProviders({
//     required HPPProvider hppProvider,
//     required OperationalProvider operationalProvider,
//     required MenuProvider menuProvider,
//   }) async {
//     try {
//       // Load saved data
//       final savedData = await StorageService.loadSharedData();
//       if (savedData != null) {
//         // Update HPP Provider
//         await hppProvider.updateVariableCosts(savedData.variableCosts);
//         await hppProvider.updateFixedCosts(savedData.fixedCosts);
//         await hppProvider.updateEstimasi(
//           savedData.estimasiPorsi,
//           savedData.estimasiProduksiBulanan,
//         );

//         // Update Operational Provider
//         await operationalProvider.updateKaryawanData(savedData.karyawan);

//         // Load menu history
//         final menuHistory = await StorageService.loadMenuHistory();
//         for (var menu in menuHistory) {
//           menuProvider._menuHistory.add(menu);
//         }
//       }

//       // Setup auto-sync
//       _setupAutoSync(hppProvider, operationalProvider, menuProvider);
//     } catch (e) {
//       debugPrint('Error initializing providers: $e');
//     }
//   }

//   static void _setupAutoSync(
//     HPPProvider hpp,
//     OperationalProvider operational,
//     MenuProvider menu,
//   ) {
//     // Listen to changes and auto-save
//     hpp.addListener(() => _scheduleAutoSave(hpp, operational, menu));
//     operational.addListener(() => _scheduleAutoSave(hpp, operational, menu));
//     menu.addListener(() => _scheduleAutoSave(hpp, operational, menu));
//   }

//   static void _scheduleAutoSave(
//     HPPProvider hpp,
//     OperationalProvider operational,
//     MenuProvider menu,
//   ) {
//     _autoSaveTimer?.cancel();
//     _autoSaveTimer = Timer(const Duration(seconds: 2), () {
//       _performAutoSave(hpp, operational, menu);
//     });
//   }

//   static Future<void> _performAutoSave(
//     HPPProvider hpp,
//     OperationalProvider operational,
//     MenuProvider menu,
//   ) async {
//     try {
//       final sharedData = _buildSharedData(hpp, operational);
//       await StorageService.autoSave(sharedData);

//       // Save current menu if complete
//       if (menu.namaMenu.isNotEmpty && menu.komposisiMenu.isNotEmpty) {
//         final currentMenu = MenuItem(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           namaMenu: menu.namaMenu,
//           komposisi: menu.komposisiMenu,
//           createdAt: DateTime.now(),
//         );
//         await StorageService.saveMenuToHistory(currentMenu);
//       }
//     } catch (e) {
//       debugPrint('Auto-save error: $e');
//     }
//   }

//   static SharedCalculationData _buildSharedData(
//     HPPProvider hpp,
//     OperationalProvider operational,
//   ) {
//     return SharedCalculationData(
//       variableCosts: hpp.data.variableCosts,
//       fixedCosts: hpp.data.fixedCosts,
//       estimasiPorsi: hpp.data.estimasiPorsi,
//       estimasiProduksiBulanan: hpp.data.estimasiProduksiBulanan,
//       hppMurniPerPorsi: hpp.data.hppMurniPerPorsi,
//       biayaVariablePerPorsi: hpp.data.biayaVariablePerPorsi,
//       biayaFixedPerPorsi: hpp.data.biayaFixedPerPorsi,
//       karyawan: operational.karyawan,
//       totalOperationalCost:
//           operational.karyawan.fold(0.0, (sum, k) => sum + k.gajiBulanan),
//       totalHargaSetelahOperational: hpp.data.hppMurniPerPorsi +
//           (operational.karyawan.isNotEmpty
//               ? operational.karyawan
//                       .fold(0.0, (sum, k) => sum + k.gajiBulanan) /
//                   (hpp.data.estimasiPorsi * hpp.data.estimasiProduksiBulanan)
//               : 0.0),
//     );
//   }

//   static Future<String?> exportAllData(
//     HPPProvider hpp,
//     OperationalProvider operational,
//     MenuProvider menu,
//   ) async {
//     try {
//       return await StorageService.exportData();
//     } catch (e) {
//       debugPrint('Export error: $e');
//       return null;
//     }
//   }

//   static Future<bool> importAllData(
//     String jsonData,
//     HPPProvider hpp,
//     OperationalProvider operational,
//     MenuProvider menu,
//   ) async {
//     try {
//       final success = await StorageService.importData(jsonData);
//       if (success) {
//         // Reload data into providers
//         await initializeProviders(
//           hppProvider: hpp,
//           operationalProvider: operational,
//           menuProvider: menu,
//         );
//       }
//       return success;
//     } catch (e) {
//       debugPrint('Import error: $e');
//       return false;
//     }
//   }

//   static void dispose() {
//     _autoSaveTimer?.cancel();
//   }
// }
