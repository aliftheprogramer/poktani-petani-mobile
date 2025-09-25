import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:niteni/pages/pupuk/list_pupuk.dart';
import 'package:niteni/services/api_service.dart';

class PemupukanAddPage extends StatefulWidget {
  final String plantingActivityId;
  const PemupukanAddPage({super.key, required this.plantingActivityId});

  @override
  State<PemupukanAddPage> createState() => _PemupukanAddPageState();
}

class _PemupukanAddPageState extends State<PemupukanAddPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Controllers
  final _pupukController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, dynamic>? _selectedPupuk;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _pupukController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _pricePerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPupuk() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const PupukSelectionPage()),
    );

    if (result != null) {
      setState(() {
        _selectedPupuk = result;
        _pupukController.text = _selectedPupuk?['name'] ?? 'Error';

        final price = (_selectedPupuk?['price'] as num?)?.toDouble() ?? 0;
        final netWeightRaw =
            (_selectedPupuk?['net_weight'] as num?)?.toDouble() ?? 1;
        final netWeightUnit =
            _selectedPupuk?['net_weight_unit']?.toString().toLowerCase() ??
            'kg';

        // Convert selected product net weight to KG for consistent API contract
        double netWeightInKg;
        if (netWeightUnit == 'kg' || netWeightUnit == 'kilogram') {
          netWeightInKg = netWeightRaw;
        } else if (netWeightUnit == 'g' || netWeightUnit == 'gram') {
          netWeightInKg = netWeightRaw / 1000.0;
        } else {
          // Fallback: assume provided value already represents kg
          netWeightInKg = netWeightRaw;
        }

        // Price per kg
        double pricePerKg = (price > 0 && netWeightInKg > 0)
            ? price / netWeightInKg
            : 0;

        _unitController.text = 'kg';
        _pricePerUnitController.text = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(pricePerKg);
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
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pricePerUnitRaw = _pricePerUnitController.text
          .replaceAll(RegExp(r'[^0-9,]'), '')
          .replaceAll(',', '.');

      // Menghitung total jumlah dalam satuan berat (e.g., kg)
      final amountInPackages = num.tryParse(_amountController.text) ?? 0;
      final netWeightRaw =
          (_selectedPupuk?['net_weight'] as num?)?.toDouble() ?? 1;
      final netWeightUnit =
          _selectedPupuk?['net_weight_unit']?.toString().toLowerCase() ?? 'kg';
      double netWeightInKg;
      if (netWeightUnit == 'kg' || netWeightUnit == 'kilogram') {
        netWeightInKg = netWeightRaw;
      } else if (netWeightUnit == 'g' || netWeightUnit == 'gram') {
        netWeightInKg = netWeightRaw / 1000.0;
      } else {
        netWeightInKg = netWeightRaw;
      }
      final totalAmountInWeight = amountInPackages * netWeightInKg;

      final body = {
        "fertilizerId": _selectedPupuk?['_id'],
        // Kirim tanggal dalam UTC ISO8601 agar sesuai dengan backend
        "date": _selectedDate?.toUtc().toIso8601String(),
        "amount": totalAmountInWeight, // Mengirim total berat ke API
        "unit": 'kg',
        "pricePerUnit": num.tryParse(pricePerUnitRaw),
        "notes": _notesController.text,
      };

      await _api.post(
        '/kegiatantanam/${widget.plantingActivityId}/pemupukan',
        data: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pemupukan berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(title: const Text('Tambah Pemupukan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPupukPicker(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildReadOnlyField(_unitController, 'Satuan Dasar'),
              const SizedBox(height: 16),
              _buildReadOnlyField(
                _pricePerUnitController,
                'Harga per Satuan Dasar',
              ),
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

  Widget _buildPupukPicker() {
    return TextFormField(
      controller: _pupukController,
      readOnly: true,
      onTap: _selectPupuk,
      decoration: const InputDecoration(
        labelText: 'Pupuk',
        hintText: 'Ketuk untuk memilih pupuk',
        suffixIcon: Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pupuk tidak boleh kosong';
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
        labelText: 'Tanggal Pemupukan',
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

  Widget _buildAmountField() {
    final stock = (_selectedPupuk?['stock'] as num?)?.toDouble() ?? 0;
    final packageUnit =
        _selectedPupuk?['package_unit']?.toString() ?? 'kemasan';

    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Jumlah Kemasan ($packageUnit)',
        helperText: 'Stok tersedia: $stock $packageUnit',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Jumlah kemasan tidak boleh kosong';
        }
        final enteredValue = double.tryParse(value);
        if (enteredValue == null) {
          return 'Masukkan angka yang valid';
        }
        if (enteredValue > stock) {
          return 'Jumlah melebihi stok yang tersedia ($stock $packageUnit)';
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
