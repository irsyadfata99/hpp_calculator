// lib/providers/operational_provider.dart - SIMPLIFIED VERSION untuk Phase 1
import 'package:flutter/foundation.dart';
import '../models/karyawan_data.dart';

class OperationalProvider with ChangeNotifier {
  List<KaryawanData> _karyawan = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  List<KaryawanData> get karyawan => _karyawan;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Temporary simple methods - will be enhanced in Phase 2
  void addKaryawan(String nama, String jabatan, double gaji) {
    // Temporary implementation
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
