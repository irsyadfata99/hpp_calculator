// lib/widgets/menu/menu_ingredient_selector_widget.dart - FIXED VERSION: PROPER LAYOUT ALIGNMENT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/universal_unit_service.dart';

class MenuIngredientSelectorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> availableIngredients;
  final Function(String, double, String, double) onAddIngredient;

  const MenuIngredientSelectorWidget({
    super.key,
    required this.availableIngredients,
    required this.onAddIngredient,
  });

  @override
  MenuIngredientSelectorWidgetState createState() =>
      MenuIngredientSelectorWidgetState();
}

class MenuIngredientSelectorWidgetState
    extends State<MenuIngredientSelectorWidget> {
  String? _selectedIngredient;
  String _selectedSatuan = '%';
  final _jumlahController = TextEditingController();

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedIngredient = null;
      _selectedSatuan = '%';
    });
    _jumlahController.clear();
  }

  // Calculate cost with improved logic and better error handling
  double _calculateCost() {
    if (_selectedIngredient == null || _jumlahController.text.isEmpty) {
      return 0.0;
    }

    try {
      // Safe ingredient lookup with orElse
      var ingredient = widget.availableIngredients.firstWhere(
        (item) => item['nama'] == _selectedIngredient,
        orElse: () => <String, dynamic>{}, // Return empty map if not found
      );

      // Validate ingredient was found and has required data
      if (ingredient.isEmpty ||
          !ingredient.containsKey('totalHarga') ||
          !ingredient.containsKey('jumlah') ||
          ingredient['totalHarga'] == null ||
          ingredient['jumlah'] == null) {
        print(
            '❌ Selected ingredient not found or invalid: $_selectedIngredient');
        return 0.0;
      }

      double jumlah = double.tryParse(_jumlahController.text) ?? 0;
      if (jumlah <= 0) return 0.0;

      // Safe extraction of ingredient data
      double totalHarga = ingredient['totalHarga'] is num
          ? (ingredient['totalHarga'] as num).toDouble()
          : 0.0;
      double packageQuantity = ingredient['jumlah'] is num
          ? (ingredient['jumlah'] as num).toDouble()
          : 0.0;

      if (totalHarga <= 0 || packageQuantity <= 0) {
        print(
            '❌ Invalid ingredient data for calculation: totalHarga=$totalHarga, jumlah=$packageQuantity');
        return 0.0;
      }

      print('🧮 Calculating cost:');
      print('  Selected: $_selectedIngredient');
      print('  Mode: $_selectedSatuan');
      print('  Jumlah: $jumlah');
      print('  Total Harga: $totalHarga');
      print('  Package Quantity: $packageQuantity');

      CalculationResult result;
      if (_selectedSatuan == '%') {
        // Percentage mode
        result = UniversalUnitService.calculatePercentageCost(
          totalPrice: totalHarga,
          packageQuantity: packageQuantity,
          percentageUsed: jumlah,
        );
        print(
            '  Percentage calculation result: ${result.isSuccess ? result.cost : 'FAILED - ${result.errorMessage}'}');
      } else {
        // Unit mode with improved validation
        result = _calculateUnitCostFixed(
          totalPrice: totalHarga,
          packageQuantity: packageQuantity,
          unitsUsed: jumlah,
          originalSatuan: ingredient['satuan']?.toString() ?? 'unit',
        );
        print(
            '  Unit calculation result: ${result.isSuccess ? result.cost : 'FAILED - ${result.errorMessage}'}');
      }

      return result.isSuccess ? result.cost : 0.0;
    } catch (e) {
      print('❌ Error calculating cost: $e');
      return 0.0;
    }
  }

  // Custom unit cost calculation with better logic
  CalculationResult _calculateUnitCostFixed({
    required double totalPrice,
    required double packageQuantity,
    required double unitsUsed,
    required String originalSatuan,
  }) {
    // Basic validation
    if (totalPrice <= 0 || packageQuantity <= 0 || unitsUsed <= 0) {
      return CalculationResult.error('Invalid input values');
    }

    // Allow flexible unit conversion scenarios
    if (unitsUsed > packageQuantity * 10) {
      // Allow up to 10x original price as safety check
      return CalculationResult.error(
          'Hasil perhitungan terlalu besar, periksa kembali jumlah');
    }

    // Calculate unit price and total cost
    double pricePerUnit = totalPrice / packageQuantity;
    double totalCost = pricePerUnit * unitsUsed;

    // Validate result is reasonable
    if (totalCost > totalPrice * 10) {
      return CalculationResult.error(
          'Hasil perhitungan terlalu besar, periksa kembali jumlah');
    }

    return CalculationResult.success(
      cost: totalCost,
      calculation:
          '${UniversalUnitService.formatRupiah(pricePerUnit)} per $originalSatuan × $unitsUsed $_selectedSatuan = ${UniversalUnitService.formatRupiah(totalCost)}',
      unitUsed:
          '$unitsUsed $_selectedSatuan dari $packageQuantity $originalSatuan',
    );
  }

  // Get unit price with same null safety pattern
  double _getUnitPrice() {
    if (_selectedIngredient == null) return 0.0;

    try {
      var ingredient = widget.availableIngredients.firstWhere(
        (item) => item['nama'] == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty ||
          !ingredient.containsKey('totalHarga') ||
          !ingredient.containsKey('jumlah')) return 0.0;

      double totalHarga = ingredient['totalHarga'] is num
          ? (ingredient['totalHarga'] as num).toDouble()
          : 0.0;
      double packageQuantity = ingredient['jumlah'] is num
          ? (ingredient['jumlah'] as num).toDouble()
          : 0.0;

      if (totalHarga <= 0 || packageQuantity <= 0) return 0.0;

      return totalHarga / packageQuantity;
    } catch (e) {
      print('❌ Error getting unit price: $e');
      return 0.0;
    }
  }

  // Build helper info dengan informasi yang lebih jelas
  Widget _buildCalculationHelper() {
    if (_selectedIngredient == null) return const SizedBox.shrink();

    try {
      var ingredient = widget.availableIngredients.firstWhere(
        (item) => item['nama'] == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty) return const SizedBox.shrink();

      if (_selectedSatuan == '%') {
        return _buildPercentageHelper(ingredient);
      } else {
        return _buildUnitHelper(ingredient);
      }
    } catch (e) {
      print('❌ Error building calculation helper: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildPercentageHelper(Map<String, dynamic> ingredient) {
    double totalHarga = ingredient['totalHarga'] is num
        ? (ingredient['totalHarga'] as num).toDouble()
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent, color: Colors.blue[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Mode Persentase - Universal untuk semua UMKM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Total belanja: ${UniversalUnitService.formatRupiah(totalHarga)}',
            style: TextStyle(fontSize: 11, color: Colors.blue[700]),
          ),
          Text(
            'Contoh: 5% = ${UniversalUnitService.formatRupiah(totalHarga * 0.05)}',
            style: TextStyle(fontSize: 11, color: Colors.blue[600]),
          ),

          // Real-time calculation
          if (_jumlahController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Biaya: ${UniversalUnitService.formatRupiah(_calculateCost())}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitHelper(Map<String, dynamic> ingredient) {
    double unitPrice = _getUnitPrice();
    String originalSatuan = ingredient['satuan']?.toString() ?? 'unit';
    double packageQuantity = ingredient['jumlah'] is num
        ? (ingredient['jumlah'] as num).toDouble()
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: Colors.green[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Mode Unit Langsung - Presisi tinggi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dibeli: ${packageQuantity.toString()} $originalSatuan',
            style: TextStyle(fontSize: 11, color: Colors.green[600]),
          ),
          Text(
            'Harga per $originalSatuan: ${UniversalUnitService.formatRupiah(unitPrice)}',
            style: TextStyle(fontSize: 11, color: Colors.green[700]),
          ),

          // Real-time calculation
          if (_jumlahController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Biaya: ${UniversalUnitService.formatRupiah(_calculateCost())}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build validation warning
  Widget _buildValidationWarning() {
    if (_selectedSatuan != '%' || _jumlahController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    double percentage = double.tryParse(_jumlahController.text) ?? 0;
    ValidationResult validation =
        UniversalUnitService.validatePercentage(percentage);

    if (!validation.isValid ||
        validation.severity == ValidationSeverity.warning) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: validation.isValid ? Colors.orange[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: validation.isValid ? Colors.orange[300]! : Colors.red[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              validation.isValid ? Icons.warning : Icons.error,
              color: validation.isValid ? Colors.orange[600] : Colors.red[600],
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                validation.message,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      validation.isValid ? Colors.orange[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _addIngredient() {
    if (_selectedIngredient != null && _jumlahController.text.isNotEmpty) {
      double? jumlah = double.tryParse(_jumlahController.text);
      if (jumlah != null && jumlah > 0) {
        // Validate percentage if needed
        if (_selectedSatuan == '%') {
          ValidationResult validation =
              UniversalUnitService.validatePercentage(jumlah);
          if (!validation.isValid) {
            print('❌ Percentage validation failed: ${validation.message}');
            return; // Don't add if invalid
          }
        }

        double cost = _calculateCost();
        if (cost <= 0) {
          print('❌ Cannot add ingredient with zero cost');
          return;
        }

        double unitPrice = cost / jumlah; // Price per unit used

        print('✅ Adding ingredient:');
        print('  Name: $_selectedIngredient');
        print('  Amount: $jumlah $_selectedSatuan');
        print('  Unit Price: ${UniversalUnitService.formatRupiah(unitPrice)}');
        print('  Total Cost: ${UniversalUnitService.formatRupiah(cost)}');

        widget.onAddIngredient(
          _selectedIngredient!,
          jumlah,
          _selectedSatuan,
          unitPrice,
        );

        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Same style as HPP calculator
            _buildHeader(),

            const SizedBox(height: 16),

            // Content
            if (widget.availableIngredients.isEmpty)
              _buildEmptyIngredientsWarning()
            else
              _buildIngredientSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Same icon and color scheme as HPP calculator
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add_shopping_cart,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Komposisi Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyIngredientsWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Belum ada data bahan. Silakan lengkapi data belanja bahan di HPP Calculator terlebih dahulu.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSelector() {
    List<String> usageUnits = UniversalUnitService.getUsageUnits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same form style as HPP calculator
        const Text('Tambah Bahan ke Menu:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Dropdown Pilih Bahan
        _buildIngredientDropdown(),

        const SizedBox(height: 12),

        // FIXED: Row untuk Jumlah dan Satuan dengan proper alignment
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Jumlah
            Expanded(
              flex: 2,
              child: _buildJumlahInput(),
            ),
            const SizedBox(width: 12),
            // FIXED: Dropdown Satuan dengan proper height alignment
            Expanded(
              child: _buildSatuanDropdown(usageUnits),
            ),
          ],
        ),

        // Calculation Helper
        _buildCalculationHelper(),

        // Validation Warning
        _buildValidationWarning(),

        const SizedBox(height: 16),

        // Tombol Tambah - Same style as HPP
        _buildAddButton(),
      ],
    );
  }

  Widget _buildIngredientDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIngredient,
      decoration: const InputDecoration(
        labelText: 'Pilih Bahan',
        hintText: 'Pilih dari daftar belanja',
        border: OutlineInputBorder(),
        filled: true,
      ),
      items: widget.availableIngredients.map((ingredient) {
        String nama = ingredient['nama']?.toString() ?? 'Unknown';
        double jumlah = ingredient['jumlah'] is num
            ? (ingredient['jumlah'] as num).toDouble()
            : 0.0;
        String satuan = ingredient['satuan']?.toString() ?? 'unit';
        double totalHarga = ingredient['totalHarga'] is num
            ? (ingredient['totalHarga'] as num).toDouble()
            : 0.0;

        return DropdownMenuItem<String>(
          value: nama,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nama,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$jumlah $satuan - ${UniversalUnitService.formatRupiah(totalHarga)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedIngredient = value;
          _jumlahController.clear();
        });
      },
    );
  }

  Widget _buildJumlahInput() {
    String hint = _selectedSatuan == '%' ? '5' : '1';
    String helper =
        _selectedSatuan == '%' ? 'Contoh: 5 (untuk 5%)' : 'Bisa desimal: 1.5';

    return TextField(
      controller: _jumlahController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Jumlah',
        hintText: hint,
        helperText: helper,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      onChanged: (value) {
        setState(() {}); // Update real-time calculation
      },
    );
  }

  // FIXED: Satuan dropdown dengan proper height alignment
  Widget _buildSatuanDropdown(List<String> units) {
    return DropdownButtonFormField<String>(
      value: _selectedSatuan,
      decoration: const InputDecoration(
        labelText: 'Satuan',
        border: OutlineInputBorder(),
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: units.map((satuan) {
        String displayText = satuan;
        if (satuan == '%') {
          displayText = '% (Persentase)';
        }
        return DropdownMenuItem<String>(
          value: satuan,
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSatuan = value ?? '%';
          _jumlahController.clear();
        });
      },
    );
  }

  Widget _buildAddButton() {
    bool canAdd =
        _selectedIngredient != null && _jumlahController.text.isNotEmpty;

    // Show estimated cost
    String buttonText = 'Tambah ke Menu';
    if (canAdd) {
      double cost = _calculateCost();
      if (cost > 0) {
        buttonText = 'Tambah - ${UniversalUnitService.formatRupiah(cost)}';
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAdd ? _addIngredient : null,
        icon: const Icon(Icons.add),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
