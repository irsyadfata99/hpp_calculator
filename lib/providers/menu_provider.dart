// lib/providers/menu_provider.dart - SIMPLIFIED VERSION untuk Phase 1
import 'package:flutter/foundation.dart';
import '../models/menu_model.dart';

class MenuProvider with ChangeNotifier {
  String _namaMenu = '';
  double _marginPercentage = 30.0;
  List<MenuComposition> _komposisiMenu = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  String get namaMenu => _namaMenu;
  double get marginPercentage => _marginPercentage;
  List<MenuComposition> get komposisiMenu => _komposisiMenu;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Temporary simple methods - will be enhanced in Phase 2
  void updateNamaMenu(String nama) {
    _namaMenu = nama;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
