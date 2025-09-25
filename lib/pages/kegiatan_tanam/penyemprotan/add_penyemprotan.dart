import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:niteni/pages/pestisida/list_pestisida.dart';
import 'package:niteni/services/api_service.dart';

class PenyemprotanAddPage extends StatefulWidget {
  final String plantingActivityId;
  const PenyemprotanAddPage({super.key, required this.plantingActivityId});

  @override
  State<PenyemprotanAddPage> createState() => _PenyemprotanAddPageState();
}

class _PenyemprotanAddPageState extends State<PenyemprotanAddPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Controllers
  final _pesticideController = TextEditingController();
  final _dateController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, dynamic>? _selectedPesticide;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    // Bersihkan semua controller
    _pesticideController.dispose();
    _dateController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    _pricePerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPesticide() async {
    // Navigasi ke halaman pemilihan dan tunggu hasilnya
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const PesticideSelectionPage()),
    );

    if (result != null) {
      setState(() {
        _selectedPesticide = result;
        _pesticideController.text = _selectedPesticide?['name'] ?? 'Error';

        // Logika untuk menghitung pricePerUnit dan mengisi unit
        final price = (_selectedPesticide?['price'] as num?)?.toDouble() ?? 0;
        final netVolume =
            (_selectedPesticide?['net_volume'] as num?)?.toDouble() ?? 1;
        final netVolumeUnit =
            _selectedPesticide?['net_volume_unit']?.toString() ?? 'unit';

        double pricePerUnit = (price > 0 && netVolume > 0)
            ? price / netVolume
            : 0;

        _unitController.text = netVolumeUnit;
        _pricePerUnitController.text = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 2,
        ).format(pricePerUnit);
      });
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(pickedDate);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Jika validasi gagal, hentikan proses
    }

    setState(() => _isSaving = true);

    try {
      final pricePerUnitRaw = _pricePerUnitController.text
          .replaceAll(RegExp(r'[^0-9,]'), '')
          .replaceAll(',', '.');
      final body = {
        "pesticideId": _selectedPesticide?['_id'],
        "date": _selectedDate?.toIso8601String(),
        "dosage": num.tryParse(_dosageController.text),
        "unit": _unitController.text,
        "pricePerUnit": num.tryParse(pricePerUnitRaw),
        "notes": _notesController.text,
      };

      // --- PERBAIKAN DI SINI ---
      // Menambahkan nama argumen 'data:' sebelum 'body'
      await _api.post(
        '/kegiatantanam/${widget.plantingActivityId}/penyemprotan',
        data: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data penyemprotan berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali dan beri sinyal untuk refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Penyemprotan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPesticidePicker(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildDosageField(),
              const SizedBox(height: 16),
              _buildReadOnlyField(_unitController, 'Satuan Dosis'),
              const SizedBox(height: 16),
              _buildReadOnlyField(_pricePerUnitController, 'Harga per Satuan'),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPesticidePicker() {
    return TextFormField(
      controller: _pesticideController,
      readOnly: true,
      onTap: _selectPesticide,
      decoration: const InputDecoration(
        labelText: 'Pestisida',
        hintText: 'Ketuk untuk memilih pestisida',
        suffixIcon: Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pestisida tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      decoration: const InputDecoration(
        labelText: 'Tanggal Penyemprotan',
        hintText: 'Pilih tanggal',
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tanggal tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDosageField() {
    final stock = (_selectedPesticide?['stock'] as num?)?.toDouble() ?? 0;
    return TextFormField(
      controller: _dosageController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Dosis',
        helperText: 'Stok tersedia: $stock ${_unitController.text}',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Dosis tidak boleh kosong';
        }
        final enteredValue = double.tryParse(value);
        if (enteredValue == null) {
          return 'Masukkan angka yang valid';
        }
        if (enteredValue > stock) {
          return 'Dosis melebihi stok yang tersedia ($stock)';
        }
        return null;
      },
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Catatan (Opsional)',
        hintText: 'Masukkan catatan tambahan di sini',
        border: OutlineInputBorder(),
      ),
    );
  }
}
