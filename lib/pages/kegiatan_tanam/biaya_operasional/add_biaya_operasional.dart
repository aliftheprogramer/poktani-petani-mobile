import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class AddBiayaOperasionalPage extends StatefulWidget {
  final String plantingActivityId;
  const AddBiayaOperasionalPage({super.key, required this.plantingActivityId});

  @override
  State<AddBiayaOperasionalPage> createState() =>
      _AddBiayaOperasionalPageState();
}

class _AddBiayaOperasionalPageState extends State<AddBiayaOperasionalPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final _dateController = TextEditingController();
  final _costTypeController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  bool _saving = false;
  final List<String> _costTypes = const [
    'Tenaga Kerja',
    'Sewa Alat',
    'Bahan Pendukung',
    'Lain-lain',
  ];
  String? _selectedCostType;

  @override
  void dispose() {
    _dateController.dispose();
    _costTypeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final amountRaw = _amountController.text
          .replaceAll(RegExp(r'[^0-9,]'), '')
          .replaceAll(',', '.');
      final body = {
        'date': _selectedDate?.toUtc().toIso8601String(),
        'costType': _selectedCostType,
        'amount': num.tryParse(amountRaw) ?? 0,
        'notes': _notesController.text.trim(),
      };
      await _api.post(
        '/kegiatantanam/${widget.plantingActivityId}/biayaoperasional',
        data: body,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biaya operasional ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Biaya Operasional')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Tanggal wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCostType,
                items: _costTypes
                    .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCostType = val;
                    _costTypeController.text = val ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Jenis Biaya',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Jenis biaya wajib dipilih'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final val = num.tryParse(
                    v.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'),
                  );
                  if (val == null || val <= 0)
                    return 'Masukkan jumlah yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
