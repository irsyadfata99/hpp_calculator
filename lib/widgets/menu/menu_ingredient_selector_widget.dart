// lib/widgets/menu/menu_ingredient_selector_widget.dart - PHASE 1.5 FIX: No Debug Spam
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

  // FIXED: Remove debug mode completely
  List<Map<String, dynamic>>? _cachedUniqueIngredients;

  @override
  void initState() {
    super.initState();
    _cacheUniqueIngredients();
  }

  @override
  void didUpdateWidget(MenuIngredientSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableIngredients != widget.availableIngredients) {
      _cacheUniqueIngredients();
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  // FIXED: Cache unique ingredients to prevent repeated processing
  void _cacheUniqueIngredients() {
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (var ingredient in widget.availableIngredients) {
      try {
        String nama = ingredient['nama']?.toString() ?? 'Unknown';
        if (nama.trim().isEmpty || nama == 'Unknown') continue;

        double jumlah = (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;
        String satuan = ingredient['satuan']?.toString() ?? 'unit';
        double totalHarga =
            (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;

        if (jumlah <= 0 || totalHarga <= 0) continue;

        String uniqueKey = '${nama}_${jumlah}_${satuan}_${totalHarga.toInt()}';

        if (!uniqueMap.containsKey(uniqueKey)) {
          uniqueMap[uniqueKey] = ingredient;
        }
      } catch (e) {
        // Skip invalid ingredients silently
        continue;
      }
    }

    _cachedUniqueIngredients = uniqueMap.values.toList();
  }

  List<Map<String, dynamic>> get _uniqueIngredients {
    return _cachedUniqueIngredients ?? [];
  }

  // FIXED: Simplified cost calculation without excessive logging
  double _calculateCost() {
    if (_selectedIngredient == null || _jumlahController.text.isEmpty) {
      return 0.0;
    }

    try {
      final ingredient = _uniqueIngredients.firstWhere(
        (item) => item['nama']?.toString() == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty) return 0.0;

      double jumlah = double.tryParse(_jumlahController.text) ?? 0;
      if (jumlah <= 0) return 0.0;

      double totalHarga = (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;
      double packageQuantity =
          (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;
      String packageUnit = ingredient['satuan']?.toString() ?? 'unit';

      if (totalHarga <= 0 || packageQuantity <= 0) return 0.0;

      CalculationResult result = UniversalUnitService.calculateSmartCost(
        totalPrice: totalHarga,
        packageQuantity: packageQuantity,
        packageUnit: packageUnit,
        usageAmount: jumlah,
        usageUnit: _selectedSatuan,
      );

      return result.isSuccess ? result.cost : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _addIngredient() {
    try {
      if (_selectedIngredient == null) {
        _showError('Please select an ingredient');
        return;
      }

      if (_jumlahController.text.isEmpty) {
        _showError('Please enter quantity');
        return;
      }

      double? jumlah = double.tryParse(_jumlahController.text);
      if (jumlah == null || jumlah <= 0) {
        _showError('Please enter valid quantity');
        return;
      }

      double cost = _calculateCost();
      if (cost <= 0) {
        _showError('Invalid cost calculation');
        return;
      }

      // FIXED: Safe unit price calculation
      double unitPrice = cost / jumlah;

      // Validate unit price is reasonable
      if (!unitPrice.isFinite || unitPrice <= 0 || unitPrice > 1000000) {
        _showError('Calculated unit price is invalid');
        return;
      }

      // Call the callback
      widget.onAddIngredient(
        _selectedIngredient!,
        jumlah,
        _selectedSatuan,
        unitPrice,
      );

      // Reset form
      _resetForm();
      _showSuccess('✅ Ingredient added successfully!');
    } catch (e) {
      _showError('Error adding ingredient: ${e.toString()}');
    }
  }

  void _resetForm() {
    setState(() {
      _selectedIngredient = null;
      _selectedSatuan = '%';
    });
    _jumlahController.clear();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
        _buildIngredientDropdown(),
        const SizedBox(height: 12),
        _buildInputRow(usageUnits),
        const SizedBox(height: 12),
        if (_selectedIngredient != null && _jumlahController.text.isNotEmpty)
          _buildCalculationPreview(),
        const SizedBox(height: 16),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildIngredientDropdown() {
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
        items: _uniqueIngredients.map((ingredient) {
          String nama = ingredient['nama']?.toString() ?? 'Unknown';
          double jumlah = (ingredient['jumlah'] as num?)?.toDouble() ?? 0.0;
          String satuan = ingredient['satuan']?.toString() ?? 'unit';
          double totalHarga =
              (ingredient['totalHarga'] as num?)?.toDouble() ?? 0.0;

          return DropdownMenuItem<String>(
            value: nama,
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

  Widget _buildInputRow(List<String> units) {
    List<String> uniqueUnits = units.toSet().toList();

    if (!uniqueUnits.contains(_selectedSatuan)) {
      _selectedSatuan = uniqueUnits.isNotEmpty ? uniqueUnits.first : '%';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount input
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
                setState(() {}); // Trigger rebuild for cost calculation
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

  Widget _buildCalculationPreview() {
    double cost = _calculateCost();

    return Container(
      padding: const EdgeInsets.all(12),
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
              Icon(Icons.calculate, color: Colors.blue[700], size: 16),
              const SizedBox(width: 6),
              const Text(
                'Calculation Preview',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cost: ${UniversalUnitService.formatRupiah(cost)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
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
