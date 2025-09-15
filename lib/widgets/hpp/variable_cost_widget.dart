// lib/widgets/hpp/variable_cost_widget.dart - CRITICAL FIX: Form Controllers + Input Parsing
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/universal_unit_service.dart';

class VariableCostWidget extends StatefulWidget {
  final List<Map<String, dynamic>> variableCosts;
  final VoidCallback onDataChanged;
  final Function(String, double, double, String) onAddItem;
  final Function(int) onRemoveItem;

  const VariableCostWidget({
    super.key,
    required this.variableCosts,
    required this.onDataChanged,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  VariableCostWidgetState createState() => VariableCostWidgetState();
}

class VariableCostWidgetState extends State<VariableCostWidget> {
  final _namaController = TextEditingController();
  final _totalHargaController = TextEditingController();
  final _jumlahController = TextEditingController();
  String _selectedSatuan = 'unit';
  bool _isProcessing = false; // CRITICAL FIX: Add processing state

  @override
  void dispose() {
    // CRITICAL FIX: Proper controller disposal
    _namaController.dispose();
    _totalHargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  // CRITICAL FIX: Enhanced input parsing
  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;

    try {
      // Remove currency formatting
      String cleaned = value.replaceAll(RegExp(r'[Rp\s,\.]'), '');
      if (cleaned.isEmpty) return null;

      double? parsed = double.tryParse(cleaned);
      if (parsed == null || !parsed.isFinite || parsed.isNaN) {
        return null;
      }

      return parsed > 0 ? parsed : null;
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      return null;
    }
  }

  // CRITICAL FIX: Enhanced form validation & submission
  Future<void> _tambahItem() async {
    if (_isProcessing) return; // Prevent double submission

    // CRITICAL FIX: Validate all inputs before processing
    final nama = _namaController.text.trim();
    final totalHargaText = _totalHargaController.text.trim();
    final jumlahText = _jumlahController.text.trim();

    if (nama.isEmpty) {
      _showError('Nama bahan tidak boleh kosong');
      return;
    }

    if (totalHargaText.isEmpty) {
      _showError('Total harga tidak boleh kosong');
      return;
    }

    if (jumlahText.isEmpty) {
      _showError('Jumlah tidak boleh kosong');
      return;
    }

    // CRITICAL FIX: Safe number parsing
    final totalHarga = _parseDouble(totalHargaText);
    final jumlah = _parseDouble(jumlahText);

    if (totalHarga == null || totalHarga <= 0) {
      _showError('Total harga harus berupa angka yang valid dan lebih dari 0');
      return;
    }

    if (jumlah == null || jumlah <= 0) {
      _showError('Jumlah harus berupa angka yang valid dan lebih dari 0');
      return;
    }

    // CRITICAL FIX: Reasonable limits validation
    if (totalHarga > 50000000) {
      // 50 million max
      _showError('Total harga terlalu besar (maksimal Rp 50 juta)');
      return;
    }

    if (jumlah > 5000) {
      // 5000 units max
      _showError('Jumlah terlalu besar (maksimal 5000 unit)');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // CRITICAL FIX: Call provider method safely
      await widget.onAddItem(nama, totalHarga, jumlah, _selectedSatuan);

      // CRITICAL FIX: Clear form only after successful addition
      if (mounted) {
        _namaController.clear();
        _totalHargaController.clear();
        _jumlahController.clear();
        _selectedSatuan = 'unit';

        _showSuccess('✅ Bahan berhasil ditambahkan');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error menambah bahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
            _buildFormInput(),
            const SizedBox(height: 12),
            _buildTambahButton(),
            if (widget.variableCosts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Daftar Belanja:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.variableCosts.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                return _buildItemTile(item, index);
              }),
              const SizedBox(height: 12),
              _buildTotalSection(),
            ],
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
            Icons.shopping_cart,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Belanja Bahan',
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

  Widget _buildFormInput() {
    List<String> packageUnits = UniversalUnitService.getPackageUnits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tambah Bahan yang Dibeli:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Nama Barang
        TextFormField(
          controller: _namaController,
          enabled: !_isProcessing, // CRITICAL FIX: Disable during processing
          decoration: const InputDecoration(
            labelText: 'Nama Bahan',
            hintText: 'Contoh: Kain Katun, Selai, Kertas A4',
            prefixIcon: Icon(Icons.inventory),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama bahan tidak boleh kosong';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Row untuk Total Harga, Jumlah, dan Satuan
        Row(
          children: [
            // Total Harga
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _totalHargaController,
                enabled: !_isProcessing,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Total Harga',
                  hintText: '50000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Total harga tidak boleh kosong';
                  }
                  final parsed = _parseDouble(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),

            // Jumlah
            Expanded(
              child: TextFormField(
                controller: _jumlahController,
                enabled: !_isProcessing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  hintText: '1',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final parsed = _parseDouble(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),

            // Dropdown Satuan
            _buildSatuanDropdown(packageUnits),
          ],
        ),

        const SizedBox(height: 8),

        // Info helper
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Nanti bisa pakai persentase (%) untuk menghitung pemakaian per produk',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSatuanDropdown(List<String> units) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: _isProcessing ? Colors.grey[100] : Colors.grey[50],
      ),
      child: DropdownButton<String>(
        value: _selectedSatuan,
        underline: const SizedBox.shrink(),
        items: units.map((String satuan) {
          return DropdownMenuItem<String>(
            value: satuan,
            child: Text(satuan),
          );
        }).toList(),
        onChanged: _isProcessing
            ? null
            : (String? newValue) {
                setState(() {
                  _selectedSatuan = newValue ?? 'unit';
                });
              },
      ),
    );
  }

  Widget _buildTambahButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _tambahItem,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isProcessing ? 'Menambahkan...' : 'Tambah ke Belanja'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessing ? Colors.grey : Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
    // CRITICAL FIX: Safe value extraction
    final nama = item['nama']?.toString() ?? 'Unknown';
    final totalHarga = _parseDouble(item['totalHarga']?.toString()) ?? 0.0;
    final jumlah = _parseDouble(item['jumlah']?.toString()) ?? 0.0;
    final satuan = item['satuan']?.toString() ?? 'unit';

    // CRITICAL FIX: Handle CalculationResult properly
    CalculationResult unitPriceResult = UniversalUnitService.calculateUnitPrice(
      totalPrice: totalHarga,
      packageQuantity: jumlah,
    );

    double hargaPerSatuan =
        unitPriceResult.isSuccess ? unitPriceResult.cost : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$jumlah $satuan - ${UniversalUnitService.formatRupiah(totalHarga)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Per $satuan: ${UniversalUnitService.formatRupiah(hargaPerSatuan)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isProcessing ? null : () => widget.onRemoveItem(index),
            icon: Icon(
              Icons.delete,
              color: _isProcessing ? Colors.grey : Colors.red,
            ),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    double totalVariableCost = 0.0;

    for (var item in widget.variableCosts) {
      final totalHarga = _parseDouble(item['totalHarga']?.toString()) ?? 0.0;
      totalVariableCost += totalHarga;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Belanja Bahan:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            UniversalUnitService.formatRupiah(totalVariableCost),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
