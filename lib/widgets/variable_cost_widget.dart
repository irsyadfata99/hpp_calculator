// File: lib/widgets/variable_cost_widget.dart (Universal)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/universal_unit_service.dart';

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

  @override
  void dispose() {
    _namaController.dispose();
    _totalHargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  void _tambahItem() {
    if (_namaController.text.isNotEmpty &&
        _totalHargaController.text.isNotEmpty &&
        _jumlahController.text.isNotEmpty) {
      double totalHarga = double.tryParse(_totalHargaController.text) ?? 0;
      double jumlah = double.tryParse(_jumlahController.text) ?? 0;

      if (totalHarga > 0 && jumlah > 0) {
        widget.onAddItem(
            _namaController.text, totalHarga, jumlah, _selectedSatuan);

        // Clear form
        _namaController.clear();
        _totalHargaController.clear();
        _jumlahController.clear();
        _selectedSatuan = 'unit';

        setState(() {});
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
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // Form Input
            _buildFormInput(),

            const SizedBox(height: 12),

            // Tombol Tambah
            _buildTambahButton(),

            // List Items
            if (widget.variableCosts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Daftar Belanja:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              // Items List
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
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Bahan',
            hintText: 'Contoh: Kain Katun, Selai, Kertas A4',
            prefixIcon: Icon(Icons.inventory),
          ),
        ),

        const SizedBox(height: 12),

        // Row untuk Total Harga, Jumlah, dan Satuan
        Row(
          children: [
            // Total Harga
            Expanded(
              flex: 2,
              child: TextField(
                controller: _totalHargaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Total Harga',
                  hintText: '50000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Jumlah
            Expanded(
              child: TextField(
                controller: _jumlahController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  hintText: '1',
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Dropdown Satuan
            _buildSatuanDropdown(packageUnits),
          ],
        ),

        const SizedBox(height: 8),

        // Info helper untuk percentage mode
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
        color: Colors.grey[50],
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
        onChanged: (String? newValue) {
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
        onPressed: _tambahItem,
        icon: const Icon(Icons.add),
        label: const Text('Tambah ke Belanja'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
    double hargaPerSatuan = UniversalUnitService.calculateUnitPrice(
      totalPrice: item['totalHarga'],
      packageQuantity: item['jumlah'],
    );

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
                  item['nama'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item['jumlah']} ${item['satuan']} - ${UniversalUnitService.formatRupiah(item['totalHarga'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Per ${item['satuan']}: ${UniversalUnitService.formatRupiah(hargaPerSatuan)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onRemoveItem(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    double totalVariableCost =
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
