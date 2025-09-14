// lib/widgets/menu/menu_ingredient_selector_widget.dart - FIXED DROPDOWN VERSION

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

  // FIXED: Cache unique ingredients to prevent dropdown errors
  List<Map<String, dynamic>> get _uniqueIngredients {
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (var ingredient in widget.availableIngredients) {
      String nama = ingredient['nama']?.toString() ?? 'Unknown';

      // Skip if name is empty or just whitespace
      if (nama.trim().isEmpty || nama == 'Unknown') continue;

      // Create unique key (name + details to handle similar names)
      double jumlah = (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;
      String satuan = ingredient['satuan']?.toString() ?? 'unit';
      double totalHarga = (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;

      String uniqueKey = '${nama}_${jumlah}_${satuan}_${totalHarga.toInt()}';

      // Only add if we haven't seen this exact combination before
      if (!uniqueMap.containsKey(uniqueKey)) {
        uniqueMap[uniqueKey] = ingredient;
      }
    }

    return uniqueMap.values.toList();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // FIXED: Reset selected ingredient if it's not in the current list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSelectedIngredient();
    });
  }

  @override
  void didUpdateWidget(MenuIngredientSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIXED: Check if selected ingredient is still valid when widget updates
    _validateSelectedIngredient();
  }

  void _validateSelectedIngredient() {
    if (_selectedIngredient != null) {
      final uniqueIngredients = _uniqueIngredients;
      bool isValid = uniqueIngredients.any((ingredient) {
        String nama = ingredient['nama']?.toString() ?? 'Unknown';
        return nama == _selectedIngredient;
      });

      if (!isValid) {
        setState(() {
          _selectedIngredient = null;
          _jumlahController.clear();
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedIngredient = null;
      _selectedSatuan = '%';
    });
    _jumlahController.clear();
  }

  // FIXED: Safe calculation with proper error handling
  double _calculateCost() {
    if (_selectedIngredient == null || _jumlahController.text.isEmpty) {
      return 0.0;
    }

    try {
      final uniqueIngredients = _uniqueIngredients;
      final ingredient = uniqueIngredients.firstWhere(
        (item) => item['nama']?.toString() == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty) return 0.0;

      double jumlah = double.tryParse(_jumlahController.text) ?? 0;
      if (jumlah <= 0) return 0.0;

      double totalHarga = (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;
      double packageQuantity =
          (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;

      if (totalHarga <= 0 || packageQuantity <= 0) return 0.0;

      CalculationResult result;
      if (_selectedSatuan == '%') {
        result = UniversalUnitService.calculatePercentageCost(
          totalPrice: totalHarga,
          packageQuantity: packageQuantity,
          percentageUsed: jumlah,
        );
      } else {
        result = UniversalUnitService.calculateUnitCost(
          totalPrice: totalHarga,
          packageQuantity: packageQuantity,
          unitsUsed: jumlah,
        );
      }

      return result.isSuccess ? result.cost : 0.0;
    } catch (e) {
      debugPrint('❌ Error calculating cost: $e');
      return 0.0;
    }
  }

  void _addIngredient() {
    if (_selectedIngredient != null && _jumlahController.text.isNotEmpty) {
      double? jumlah = double.tryParse(_jumlahController.text);
      if (jumlah != null && jumlah > 0) {
        double cost = _calculateCost();
        if (cost > 0) {
          double unitPrice = cost / jumlah;

          try {
            widget.onAddIngredient(
              _selectedIngredient!,
              jumlah,
              _selectedSatuan,
              unitPrice,
            );
            _resetForm();
          } catch (e) {
            debugPrint('❌ Error adding ingredient: $e');
          }
        }
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
            _buildHeader(),
            const SizedBox(height: 16),
            if (_uniqueIngredients.isEmpty)
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
            'Menu Composition',
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
              'No ingredient data available. Please add ingredients in HPP Calculator first.',
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
        const Text('Add Ingredient to Menu:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // FIXED: Dropdown with proper constraints and unique values
        _buildIngredientDropdown(),

        const SizedBox(height: 12),

        // FIXED: Input row with proper flex constraints
        _buildInputRow(usageUnits),

        const SizedBox(height: 16),

        // Add Button
        _buildAddButton(),
      ],
    );
  }

  // FIXED: Dropdown with unique values and proper error handling
  Widget _buildIngredientDropdown() {
    final uniqueIngredients = _uniqueIngredients;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 60),
      child: DropdownButtonFormField<String>(
        value: _selectedIngredient,
        decoration: const InputDecoration(
          labelText: 'Select Ingredient',
          border: OutlineInputBorder(),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        hint: const Text('Choose an ingredient...'),
        // FIXED: Use unique ingredients only
        items: uniqueIngredients.map((ingredient) {
          String nama = ingredient['nama']?.toString() ?? 'Unknown';
          double jumlah = (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;
          String satuan = ingredient['satuan']?.toString() ?? 'unit';
          double totalHarga =
              (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;

          return DropdownMenuItem<String>(
            value: nama, // Now guaranteed to be unique
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$jumlah $satuan - ${UniversalUnitService.formatRupiah(totalHarga)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an ingredient';
          }
          return null;
        },
      ),
    );
  }

  // FIXED: Input row with proper constraints
  Widget _buildInputRow(List<String> units) {
    // FIXED: Ensure units list has unique values
    List<String> uniqueUnits = units.toSet().toList();

    // FIXED: Validate selected unit
    if (!uniqueUnits.contains(_selectedSatuan)) {
      _selectedSatuan = uniqueUnits.isNotEmpty ? uniqueUnits.first : '%';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jumlah input
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _jumlahController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: _selectedSatuan == '%' ? '5' : '1',
                border: const OutlineInputBorder(),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {}); // Update calculation
              },
            ),
          ),

          const SizedBox(width: 12),

          // Unit dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSatuan,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: uniqueUnits.map((satuan) {
                String displayText = satuan == '%' ? '% (Percentage)' : satuan;
                return DropdownMenuItem<String>(
                  value: satuan,
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSatuan = value ?? '%';
                  _jumlahController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    bool canAdd = _selectedIngredient != null &&
        _jumlahController.text.isNotEmpty &&
        _uniqueIngredients.isNotEmpty;

    String buttonText = 'Add to Menu';
    if (canAdd) {
      double cost = _calculateCost();
      if (cost > 0) {
        buttonText = 'Add - ${UniversalUnitService.formatRupiah(cost)}';
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
