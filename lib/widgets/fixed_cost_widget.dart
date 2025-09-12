import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FixedCostWidget extends StatefulWidget {
  final List<Map<String, dynamic>> fixedCosts;
  final VoidCallback onDataChanged;
  final Function(String, double) onAddItem;
  final Function(int) onRemoveItem;

  const FixedCostWidget({
    Key? key,
    required this.fixedCosts,
    required this.onDataChanged,
    required this.onAddItem,
    required this.onRemoveItem,
  }) : super(key: key);

  @override
  _FixedCostWidgetState createState() => _FixedCostWidgetState();
}

class _FixedCostWidgetState extends State<FixedCostWidget> {
  final _jenisController = TextEditingController();
  final _nominalController = TextEditingController();

  @override
  void dispose() {
    _jenisController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _tambahItem() {
    if (_jenisController.text.isNotEmpty &&
        _nominalController.text.isNotEmpty) {
      double nominal = double.tryParse(_nominalController.text) ?? 0;

      if (nominal > 0) {
        widget.onAddItem(_jenisController.text, nominal);

        // Clear form
        _jenisController.clear();
        _nominalController.clear();

        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF48B3AF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Color(0xFF48B3AF),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fixed Cost (Bulanan)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF48B3AF),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Form Input Sederhana
            Text('Tambah Biaya Tetap:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),

            // Jenis Biaya
            TextField(
              controller: _jenisController,
              decoration: InputDecoration(
                labelText: 'Jenis Biaya',
                hintText: 'Contoh: Sewa Tempat, Listrik, Gaji',
                prefixIcon: Icon(Icons.category),
              ),
            ),

            SizedBox(height: 12),

            // Nominal Bulanan
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nominal per Bulan',
                hintText: '1500000',
                prefixText: 'Rp ',
                suffixText: '/bulan',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),

            SizedBox(height: 12),

            // Tombol Tambah
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _tambahItem,
                icon: Icon(Icons.add),
                label: Text('Tambah Biaya Tetap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF48B3AF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (widget.fixedCosts.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text('Daftar Biaya Tetap:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
            ],

            // List Fixed Costs
            ...widget.fixedCosts.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF48B3AF).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF48B3AF).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF48B3AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getIconForBiaya(item['jenis']),
                        color: Color(0xFF48B3AF),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['jenis'],
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_formatRupiah(item['nominal'])}/bulan',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'Per hari: ${_formatRupiah(item['nominal'] / 30)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF48B3AF),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.onRemoveItem(index),
                      icon: Icon(Icons.delete, color: Colors.red),
                      iconSize: 20,
                    ),
                  ],
                ),
              );
            }).toList(),

            if (widget.fixedCosts.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF48B3AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF48B3AF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Fixed Cost/Bulan:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatRupiah(widget.fixedCosts
                              .fold(0.0, (sum, item) => sum + item['nominal'])),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF48B3AF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Per hari:',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          _formatRupiah(widget.fixedCosts.fold(
                                  0.0, (sum, item) => sum + item['nominal']) /
                              30),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF48B3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForBiaya(String jenis) {
    String jenisLower = jenis.toLowerCase();

    if (jenisLower.contains('sewa')) {
      return Icons.home;
    } else if (jenisLower.contains('listrik') || jenisLower.contains('air')) {
      return Icons.electrical_services;
    } else if (jenisLower.contains('gaji') || jenisLower.contains('karyawan')) {
      return Icons.people;
    } else if (jenisLower.contains('internet') ||
        jenisLower.contains('telepon')) {
      return Icons.wifi;
    } else {
      return Icons.account_balance_wallet;
    }
  }
}
