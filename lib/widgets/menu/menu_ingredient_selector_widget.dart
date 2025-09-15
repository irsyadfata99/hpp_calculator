// File: lib/widgets/menu/menu_ingredient_selector_widget.dart (WORKING VERSION - Bug #17 Fixed)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Cache untuk mencegah rebuild yang tidak perlu
  List<Map<String, dynamic>>? _cachedIngredients;
  int _ingredientHashCode = 0;

  @override
  void initState() {
    super.initState();
    _updateIngredientCache();
  }

  // 🔧 FIX UNTUK BUG #17: Cache Invalidation - WORKING VERSION
  @override
  void didUpdateWidget(MenuIngredientSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if availableIngredients has changed
    if (_hasIngredientsChanged(
        oldWidget.availableIngredients, widget.availableIngredients)) {
      debugPrint(
          '🔄 MenuIngredientSelector: Ingredients changed, refreshing cache');

      // Reset form jika ingredient yang dipilih sudah tidak ada
      if (_selectedIngredient != null) {
        bool ingredientStillExists = widget.availableIngredients
            .any((ingredient) => ingredient['nama'] == _selectedIngredient);

        if (!ingredientStillExists) {
          debugPrint('⚠️ Selected ingredient no longer exists, resetting form');
          _resetForm();
        }
      }

      // Update cache
      _updateIngredientCache();

      // Force rebuild untuk memperbarui dropdown
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  // Helper method untuk update cache
  void _updateIngredientCache() {
    _cachedIngredients =
        List<Map<String, dynamic>>.from(widget.availableIngredients);
    _ingredientHashCode = widget.availableIngredients.hashCode;
  }

  // Helper method untuk check perubahan ingredients
  bool _hasIngredientsChanged(
    List<Map<String, dynamic>> oldIngredients,
    List<Map<String, dynamic>> newIngredients,
  ) {
    if (oldIngredients.length != newIngredients.length) {
      return true;
    }

    // Check hash code dulu untuk performa
    int newHashCode = newIngredients.hashCode;
    if (_ingredientHashCode != newHashCode) {
      return true;
    }

    // Deep comparison jika hash sama tapi perlu memastikan
    for (int i = 0; i < oldIngredients.length; i++) {
      final oldItem = oldIngredients[i];
      final newItem = newIngredients[i];

      if (oldItem['nama'] != newItem['nama'] ||
          oldItem['totalHarga'] != newItem['totalHarga'] ||
          oldItem['jumlah'] != newItem['jumlah'] ||
          oldItem['satuan'] != newItem['satuan']) {
        return true;
      }
    }

    return false;
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _selectedIngredient = null;
        _selectedSatuan = '%';
      });
      _jumlahController.clear();
    }
  }

  // Calculate cost berdasarkan mode yang dipilih - SIMPLIFIED VERSION
  double _calculateCost() {
    if (_selectedIngredient == null || _jumlahController.text.isEmpty) {
      return 0.0;
    }

    try {
      // Gunakan cached ingredients untuk performa
      var ingredient =
          (_cachedIngredients ?? widget.availableIngredients).firstWhere(
        (item) => item['nama'] == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty) {
        debugPrint('⚠️ Warning: Selected ingredient not found in cache');
        return 0.0;
      }

      double jumlah = double.tryParse(_jumlahController.text) ?? 0;
      double totalHarga = ingredient['totalHarga']?.toDouble() ?? 0;
      double packageQuantity = ingredient['jumlah']?.toDouble() ?? 1;

      if (totalHarga <= 0 || packageQuantity <= 0 || jumlah <= 0) {
        return 0.0;
      }

      if (_selectedSatuan == '%') {
        // Percentage mode: (totalHarga * percentage) / 100
        if (jumlah > 100) jumlah = 100; // Cap at 100%
        return (totalHarga * jumlah) / 100;
      } else {
        // Unit mode: (totalHarga / packageQuantity) * unitsUsed
        return (totalHarga / packageQuantity) * jumlah;
      }
    } catch (e) {
      debugPrint('❌ Error calculating cost: $e');
      return 0.0;
    }
  }

  // Get unit price untuk reference - SIMPLIFIED
  double _getUnitPrice() {
    if (_selectedIngredient == null) return 0.0;

    try {
      var ingredient =
          (_cachedIngredients ?? widget.availableIngredients).firstWhere(
        (item) => item['nama'] == _selectedIngredient,
        orElse: () => <String, dynamic>{},
      );

      if (ingredient.isEmpty) return 0.0;

      double totalHarga = ingredient['totalHarga']?.toDouble() ?? 0;
      double packageQuantity = ingredient['jumlah']?.toDouble() ?? 1;

      if (totalHarga <= 0 || packageQuantity <= 0) return 0.0;

      return totalHarga / packageQuantity;
    } catch (e) {
      debugPrint('❌ Error getting unit price: $e');
      return 0.0;
    }
  }

  // Build helper info berdasarkan mode
  Widget _buildCalculationHelper() {
    if (_selectedIngredient == null) return const SizedBox.shrink();

    var ingredient =
        (_cachedIngredients ?? widget.availableIngredients).firstWhere(
      (item) => item['nama'] == _selectedIngredient,
      orElse: () => <String, dynamic>{},
    );

    if (ingredient.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Ingredient yang dipilih tidak lagi tersedia. Silakan pilih yang lain.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedSatuan == '%') {
      return _buildPercentageHelper(ingredient);
    } else {
      return _buildUnitHelper(ingredient);
    }
  }

  Widget _buildPercentageHelper(Map<String, dynamic> ingredient) {
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
                'Mode Persentase (Cocok untuk semua UMKM)',
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
            'Total belanja: ${_formatRupiah(ingredient['totalHarga'])}',
            style: TextStyle(fontSize: 11, color: Colors.blue[700]),
          ),
          Text(
            'Contoh: 5% = ${_formatRupiah((ingredient['totalHarga']?.toDouble() ?? 0) * 0.05)}',
            style: TextStyle(fontSize: 11, color: Colors.blue[600]),
          ),

          // Real-time calculation
          if (_jumlahController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Biaya: ${_formatRupiah(_calculateCost())}',
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
                'Mode Unit Langsung',
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
            'Harga per ${ingredient['satuan']}: ${_formatRupiah(unitPrice)}',
            style: TextStyle(fontSize: 11, color: Colors.green[700]),
          ),

          // Real-time calculation
          if (_jumlahController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Biaya: ${_formatRupiah(_calculateCost())}',
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

  // Build validation warning - SIMPLIFIED
  Widget _buildValidationWarning() {
    if (_selectedSatuan != '%' || _jumlahController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    double percentage = double.tryParse(_jumlahController.text) ?? 0;

    String? warningMessage;
    Color warningColor = Colors.orange;

    if (percentage <= 0) {
      warningMessage = 'Persentase harus lebih dari 0%';
      warningColor = Colors.red;
    } else if (percentage > 100) {
      warningMessage = 'Persentase lebih dari 100% - pastikan ini benar';
      warningColor = Colors.orange;
    } else if (percentage > 50) {
      warningMessage = 'Persentase cukup tinggi - pastikan sesuai kebutuhan';
      warningColor = Colors.orange;
    }

    if (warningMessage != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              warningColor == Colors.red ? Colors.red[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: warningColor == Colors.red
                ? Colors.red[300]!
                : Colors.orange[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              warningColor == Colors.red ? Icons.error : Icons.warning,
              color: warningColor == Colors.red
                  ? Colors.red[600]
                  : Colors.orange[600],
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                warningMessage,
                style: TextStyle(
                  fontSize: 11,
                  color: warningColor == Colors.red
                      ? Colors.red[700]
                      : Colors.orange[700],
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
        // Basic validation untuk percentage
        if (_selectedSatuan == '%') {
          if (jumlah > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Persentase tidak boleh lebih dari 100%'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }

        double cost = _calculateCost();
        if (cost <= 0) {
          debugPrint('⚠️ Cannot add ingredient with zero or negative cost');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Tidak dapat menambahkan ingredient dengan biaya nol'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        double unitPrice = cost / jumlah; // Price per unit yang dipakai

        try {
          widget.onAddIngredient(
            _selectedIngredient!,
            jumlah,
            _selectedSatuan,
            unitPrice,
          );

          debugPrint('✅ Ingredient added successfully: $_selectedIngredient');

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $_selectedIngredient berhasil ditambahkan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          _resetForm();
        } catch (e) {
          debugPrint('❌ Error adding ingredient: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper untuk format rupiah
  String _formatRupiah(dynamic amount) {
    try {
      double value = amount is double ? amount : (amount?.toDouble() ?? 0);
      if (value.isNaN || value.isInfinite) return 'Rp 0';

      return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}';
    } catch (e) {
      return 'Rp 0';
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
            // Header
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
            'Komposisi Produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        // Badge untuk debugging - hanya tampil jika ada ingredients
        if (widget.availableIngredients.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.availableIngredients.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
              'Belum ada data bahan. Silakan lengkapi data belanja bahan terlebih dahulu.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSelector() {
    // Basic units untuk dropdown
    List<String> usageUnits = [
      '%',
      'gram',
      'kg',
      'ml',
      'liter',
      'buah',
      'sachet'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Pilih Bahan
        _buildIngredientDropdown(),

        const SizedBox(height: 16),

        // Row untuk Jumlah dan Satuan
        Row(
          children: [
            // Input Jumlah
            Expanded(
              flex: 2,
              child: _buildJumlahInput(),
            ),
            const SizedBox(width: 12),
            // Dropdown Satuan
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

        // Tombol Tambah
        _buildAddButton(),
      ],
    );
  }

  Widget _buildIngredientDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIngredient,
      decoration: const InputDecoration(
        labelText: 'Pilih Bahan',
        hintText: 'Pilih bahan dari daftar belanja',
        prefixIcon: Icon(Icons.inventory),
      ),
      items: widget.availableIngredients.map((ingredient) {
        return DropdownMenuItem<String>(
          value: ingredient['nama'],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ingredient['nama'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${ingredient['jumlah'] ?? 0} ${ingredient['satuan'] ?? ''} - ${_formatRupiah(ingredient['totalHarga'])}',
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
        if (mounted) {
          setState(() {
            _selectedIngredient = value;
            _jumlahController.clear();
          });
        }
      },
    );
  }

  Widget _buildJumlahInput() {
    String hint = _selectedSatuan == '%' ? '5' : '1';
    String helper =
        _selectedSatuan == '%' ? 'Masukkan persentase' : 'Bisa desimal';

    return TextField(
      controller: _jumlahController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Jumlah',
        hintText: hint,
        prefixIcon:
            Icon(_selectedSatuan == '%' ? Icons.percent : Icons.straighten),
        helperText: helper,
      ),
      onChanged: (value) {
        if (mounted) {
          setState(() {}); // Update real-time calculation
        }
      },
    );
  }

  Widget _buildSatuanDropdown(List<String> units) {
    return DropdownButtonFormField<String>(
      value: _selectedSatuan,
      decoration: const InputDecoration(
        labelText: 'Satuan',
        prefixIcon: Icon(Icons.scale),
      ),
      items: units.map((satuan) {
        String displayText = satuan;
        if (satuan == '%') {
          displayText = '% (Persentase)';
        }
        return DropdownMenuItem<String>(
          value: satuan,
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (value) {
        if (mounted) {
          setState(() {
            _selectedSatuan = value ?? '%';
            _jumlahController.clear();
          });
        }
      },
    );
  }

  Widget _buildAddButton() {
    bool canAdd =
        _selectedIngredient != null && _jumlahController.text.isNotEmpty;

    // Show estimated cost
    String buttonText = 'Tambah ke Produk';
    if (canAdd) {
      double cost = _calculateCost();
      if (cost > 0) {
        buttonText = 'Tambah - ${_formatRupiah(cost)}';
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
