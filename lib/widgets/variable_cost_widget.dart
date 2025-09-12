import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String _selectedSatuan = 'kg';

  static const List<String> _satuanOptions = [
    'kg',
    'gram',
    'liter',
    'ml',
    'pcs',
    'pack'
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _totalHargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
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
        _selectedSatuan = 'kg';

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
              const Text('Daftar Bahan:',
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
            'Variable Cost',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tambah Bahan Baku:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Nama Barang
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Barang',
            hintText: 'Contoh: Beras, Ayam, Minyak',
            prefixIcon: Icon(Icons.inventory),
          ),
        ),

        const SizedBox(height: 12),

        // Row untuk Total Harga, Jumlah, dan Satuan
        Row(
          children: [
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
            Expanded(
              child: TextField(
                controller: _jumlahController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  hintText: '5',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Dropdown Satuan
            _buildSatuanDropdown(),
          ],
        ),
      ],
    );
  }

  Widget _buildSatuanDropdown() {
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
        items: _satuanOptions.map((String satuan) {
          return DropdownMenuItem<String>(
            value: satuan,
            child: Text(satuan),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedSatuan = newValue ?? 'kg';
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
        label: const Text('Tambah Bahan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, int index) {
    double hargaPerSatuan = item['totalHarga'] / item['jumlah'];

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
                  '${item['jumlah']} ${item['satuan']} - ${_formatRupiah(item['totalHarga'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Per ${item['satuan']}: ${_formatRupiah(hargaPerSatuan)}',
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
            'Total Variable Cost:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatRupiah(totalVariableCost),
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
