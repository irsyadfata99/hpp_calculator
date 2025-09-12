// lib/widgets/optimized_variable_cost_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';

class OptimizedVariableCostWidget extends StatefulWidget {
  final List<Map<String, dynamic>> variableCosts;
  final VoidCallback onDataChanged;
  final Function(String, double, double, String) onAddItem;
  final Function(int) onRemoveItem;

  const OptimizedVariableCostWidget({
    super.key,
    required this.variableCosts,
    required this.onDataChanged,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  OptimizedVariableCostWidgetState createState() =>
      OptimizedVariableCostWidgetState();
}

class OptimizedVariableCostWidgetState
    extends State<OptimizedVariableCostWidget> {
  final _namaController = TextEditingController();
  final _totalHargaController = TextEditingController();
  final _jumlahController = TextEditingController();
  String _selectedSatuan = 'unit';

  // Debouncing untuk mencegah perhitungan berlebihan
  Timer? _debounceTimer;

  // Validation state
  String? _namaError;
  String? _hargaError;
  String? _jumlahError;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _namaController.dispose();
    _totalHargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateInputs();
      widget.onDataChanged();
    });
  }

  void _validateInputs() {
    setState(() {
      _namaError = _namaController.text.trim().isEmpty
          ? 'Nama tidak boleh kosong'
          : null;

      double? harga = double.tryParse(_totalHargaController.text);
      _hargaError =
          (harga == null || harga <= 0) ? 'Harga harus lebih dari 0' : null;

      double? jumlah = double.tryParse(_jumlahController.text);
      _jumlahError =
          (jumlah == null || jumlah <= 0) ? 'Jumlah harus lebih dari 0' : null;
    });
  }

  bool get _isFormValid =>
      _namaError == null && _hargaError == null && _jumlahError == null;

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
              _buildItemsList(),
              const SizedBox(height: 12),
              _buildTotalSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Barang
        TextFormField(
          controller: _namaController,
          decoration: InputDecoration(
            labelText: 'Nama Bahan',
            hintText: 'Contoh: Kain Katun, Selai, Kertas A4',
            prefixIcon: const Icon(Icons.inventory),
            errorText: _namaError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (_) => _onInputChanged(),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            // Total Harga
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _totalHargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Harga',
                  hintText: '50000',
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(Icons.attach_money),
                  errorText: _hargaError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => _onInputChanged(),
              ),
            ),
            const SizedBox(width: 12),

            // Jumlah
            Expanded(
              child: TextFormField(
                controller: _jumlahController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  hintText: '1',
                  errorText: _jumlahError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => _onInputChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTambahButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isFormValid ? _tambahItem : null,
        icon: const Icon(Icons.add),
        label: const Text('Tambah ke Belanja'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          disabledBackgroundColor: Colors.grey[300],
        ),
      ),
    );
  }

  // Menggunakan ListView.builder untuk performa yang lebih baik
  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daftar Belanja:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.variableCosts.length *
              80.0, // Fixed height untuk mencegah overflow
          child: ListView.builder(
            itemCount: widget.variableCosts.length,
            itemBuilder: (context, index) {
              return _buildItemTile(widget.variableCosts[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child:
              Text('${index + 1}', style: TextStyle(color: Colors.green[700])),
        ),
        title: Text(item['nama'],
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item['jumlah']} ${item['satuan']} - Rp ${item['totalHarga'].toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          onPressed: () => widget.onRemoveItem(index),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    double total =
        widget.variableCosts.fold(0.0, (sum, item) => sum + item['totalHarga']);

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
          const Text('Total Belanja:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Rp ${total.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
        ],
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
          child: Icon(Icons.shopping_cart, color: Colors.green[700], size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Belanja Bahan',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ],
    );
  }

  void _tambahItem() {
    if (_isFormValid) {
      double totalHarga = double.parse(_totalHargaController.text);
      double jumlah = double.parse(_jumlahController.text);

      widget.onAddItem(
          _namaController.text.trim(), totalHarga, jumlah, _selectedSatuan);

      // Clear form
      _namaController.clear();
      _totalHargaController.clear();
      _jumlahController.clear();
      _selectedSatuan = 'unit';

      // Clear validation errors
      setState(() {
        _namaError = null;
        _hargaError = null;
        _jumlahError = null;
      });
    }
  }
}
