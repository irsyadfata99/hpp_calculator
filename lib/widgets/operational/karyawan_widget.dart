// lib/widgets/operational/karyawan_widget.dart - CRITICAL FIX: Form Controllers + Input Parsing
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
  bool _isProcessing = false; // CRITICAL FIX: Add processing state

  @override
  void dispose() {
    // CRITICAL FIX: Proper controller disposal
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

  // CRITICAL FIX: Enhanced salary parsing
  double? _parseGaji(String value) {
    if (value.trim().isEmpty) return null;

    try {
      // Remove currency formatting
      String cleaned = value.replaceAll(RegExp(r'[Rp\s,\.]'), '');
      if (cleaned.isEmpty) return null;

      double? parsed = double.tryParse(cleaned);
      if (parsed == null || !parsed.isFinite || parsed.isNaN) {
        return null;
      }

      // CRITICAL FIX: Reasonable salary range
      if (parsed < 100000 || parsed > 15000000) {
        return null;
      }

      return parsed;
    } catch (e) {
      debugPrint('❌ Salary parse error: $e');
      return null;
    }
  }

  // CRITICAL FIX: Enhanced form validation & submission
  Future<void> _tambahKaryawan() async {
    if (_isProcessing) return; // Prevent double submission

    // CRITICAL FIX: Validate all inputs before processing
    final nama = _namaController.text.trim();
    final jabatan = _jabatanController.text.trim();
    final gajiText = _gajiController.text.trim();

    if (nama.isEmpty) {
      _showError('Nama karyawan tidak boleh kosong');
      return;
    }

    if (nama.length < 2) {
      _showError('Nama karyawan minimal 2 karakter');
      return;
    }

    if (jabatan.isEmpty) {
      _showError('Jabatan tidak boleh kosong');
      return;
    }

    if (jabatan.length < 2) {
      _showError('Jabatan minimal 2 karakter');
      return;
    }

    if (gajiText.isEmpty) {
      _showError('Gaji tidak boleh kosong');
      return;
    }

    // CRITICAL FIX: Safe salary parsing
    final gaji = _parseGaji(gajiText);

    if (gaji == null) {
      _showError('Gaji harus berupa angka antara Rp 100.000 - Rp 15.000.000');
      return;
    }

    // Check for duplicate names
    bool isDuplicate = widget.sharedData.karyawan.any((k) =>
        k.namaKaryawan.toLowerCase().trim() == nama.toLowerCase().trim());

    if (isDuplicate) {
      _showError('Nama karyawan sudah ada. Gunakan nama yang berbeda.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // CRITICAL FIX: Call provider method safely
      await widget.onAddKaryawan(nama, jabatan, gaji);
      print('🔍 After widget.onAddKaryawan called');
      // CRITICAL FIX: Clear form only after successful addition
      if (mounted) {
        _namaController.clear();
        _jabatanController.clear();
        _gajiController.clear();

        _showSuccess('✅ Karyawan berhasil ditambahkan');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error menambah karyawan: ${e.toString()}');
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
    print('🏗️ KaryawanWidget building...');
    print('👥 SharedData karyawan: ${widget.sharedData.karyawan.length}');
    print('👥 SharedData object: ${widget.sharedData.hashCode}');
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
        TextFormField(
          controller: _namaController,
          enabled: !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Nama Karyawan',
            hintText: 'Contoh: Budi Santoso',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama karyawan tidak boleh kosong';
            }
            if (value.trim().length < 2) {
              return 'Nama minimal 2 karakter';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Row untuk Jabatan dan Gaji
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _jabatanController,
                enabled: !_isProcessing,
                decoration: const InputDecoration(
                  labelText: 'Jabatan',
                  hintText: 'Contoh: Kasir, Koki',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jabatan tidak boleh kosong';
                  }
                  if (value.trim().length < 2) {
                    return 'Jabatan minimal 2 karakter';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _gajiController,
                enabled: !_isProcessing,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Gaji/Bulan',
                  hintText: '2500000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Gaji tidak boleh kosong';
                  }
                  final parsed = _parseGaji(value);
                  if (parsed == null) {
                    return 'Gaji harus antara 100rb - 15jt';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Info helper
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Gaji akan dihitung sebagai biaya operasional bulanan',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTambahButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _tambahKaryawan,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isProcessing ? 'Menambahkan...' : 'Tambah Karyawan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessing ? Colors.grey : Colors.orange[600],
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
            onPressed:
                _isProcessing ? null : () => widget.onRemoveKaryawan(index),
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
