import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/karyawan_data.dart';
import '../../models/shared_calculation_data.dart';

class KaryawanWidget extends StatefulWidget {
  final SharedCalculationData sharedData;
  final VoidCallback onDataChanged;
  final Function(String, String, double) onAddKaryawan;
  final Function(int) onRemoveKaryawan;

  const KaryawanWidget({
    super.key,
    required this.sharedData,
    required this.onDataChanged,
    required this.onAddKaryawan,
    required this.onRemoveKaryawan,
  });

  @override
  KaryawanWidgetState createState() => KaryawanWidgetState();
}

class KaryawanWidgetState extends State<KaryawanWidget> {
  final _namaController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _gajiController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _jabatanController.dispose();
    _gajiController.dispose();
    super.dispose();
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _tambahKaryawan() {
    if (_namaController.text.isNotEmpty &&
        _jabatanController.text.isNotEmpty &&
        _gajiController.text.isNotEmpty) {
      double gaji = double.tryParse(_gajiController.text) ?? 0;

      if (gaji > 0) {
        widget.onAddKaryawan(
            _namaController.text, _jabatanController.text, gaji);

        // Clear form
        _namaController.clear();
        _jabatanController.clear();
        _gajiController.clear();

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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFormInput(),
            const SizedBox(height: 12),
            _buildTambahButton(),
            if (widget.sharedData.karyawan.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Daftar Karyawan:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.sharedData.karyawan.asMap().entries.map((entry) {
                int index = entry.key;
                KaryawanData karyawan = entry.value;
                return _buildKaryawanItem(karyawan, index);
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
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.people,
            color: Colors.orange[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Data Karyawan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
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
        const Text('Tambah Karyawan:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Nama Karyawan
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Karyawan',
            hintText: 'Contoh: Budi Santoso',
            prefixIcon: Icon(Icons.person),
          ),
        ),

        const SizedBox(height: 12),

        // Row untuk Jabatan dan Gaji
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _jabatanController,
                decoration: const InputDecoration(
                  labelText: 'Jabatan',
                  hintText: 'Contoh: Kasir, Koki',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _gajiController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Gaji/Bulan',
                  hintText: '2500000',
                  prefixText: 'Rp ',
                ),
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
        onPressed: _tambahKaryawan,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Karyawan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildKaryawanItem(KaryawanData karyawan, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getIconForJabatan(karyawan.jabatan),
              color: Colors.orange[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  karyawan.namaKaryawan,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  karyawan.jabatan,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${_formatRupiah(karyawan.gajiBulanan)}/bulan',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onRemoveKaryawan(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    double totalGaji = widget.sharedData.calculateTotalOperationalCost();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Gaji Karyawan/Bulan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatRupiah(totalGaji),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Per hari:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                _formatRupiah(totalGaji / 30),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForJabatan(String jabatan) {
    String jabatanLower = jabatan.toLowerCase();

    if (jabatanLower.contains('kasir') || jabatanLower.contains('cashier')) {
      return Icons.point_of_sale;
    } else if (jabatanLower.contains('koki') || jabatanLower.contains('chef')) {
      return Icons.restaurant;
    } else if (jabatanLower.contains('pelayan') ||
        jabatanLower.contains('waiter')) {
      return Icons.room_service;
    } else if (jabatanLower.contains('manager') ||
        jabatanLower.contains('manajer')) {
      return Icons.manage_accounts;
    } else if (jabatanLower.contains('cleaning') ||
        jabatanLower.contains('kebersihan')) {
      return Icons.cleaning_services;
    } else {
      return Icons.person;
    }
  }
}
