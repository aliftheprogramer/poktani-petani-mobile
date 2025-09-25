import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:niteni/pages/semaian/semaian_page.dart';
import 'package:niteni/services/api_service.dart';

class KegiatanTanamFromNurseryPage extends StatefulWidget {
  final String landId;
  const KegiatanTanamFromNurseryPage({super.key, required this.landId});

  @override
  State<KegiatanTanamFromNurseryPage> createState() =>
      _KegiatanTanamFromNurseryPageState();
}

class _KegiatanTanamFromNurseryPageState
    extends State<KegiatanTanamFromNurseryPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  Map<String, dynamic>? _selectedNursery;
  final _plantingDateController = TextEditingController();
  final _plantingAmountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _plantingDateController.dispose();
    _plantingAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPlantingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _plantingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectNursery() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SemaianPage(isSelectionMode: true),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedNursery = result;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedNursery == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih semaian terlebih dahulu'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final nurseryData = _selectedNursery!;
        final seedId = nurseryData['seedId']?['_id'];

        if (seedId == null) {
          throw Exception('ID Benih tidak ditemukan di data semaian.');
        }

        final requestBody = {
          "landId": widget.landId,
          "seedId": seedId,
          "plantingDate": DateTime.parse(
            _plantingDateController.text,
          ).toIso8601String(),
          "plantingAmount": int.parse(_plantingAmountController.text),
          "source": {"type": "FROM_NURSERY", "nurseryId": nurseryData['_id']},
          "notes": _notesController.text,
        };

        final response = await _api.post('/kegiatantanam', data: requestBody);

        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kegiatan tanam berhasil ditambahkan'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menambahkan kegiatan tanam: ${response.data['message'] ?? 'Error'}',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tanam dari Semai')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNurseryPicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plantingDateController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Tanam',
                  hintText: 'Pilih tanggal',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: _selectPlantingDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal tanam tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plantingAmountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Tanam',
                  hintText: 'Masukkan jumlah bibit yang ditanam',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tanam tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              if (_selectedNursery != null &&
                  _selectedNursery!['seedlingYield'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Jumlah bibit yang bisa ditanam maks: ${_selectedNursery!['seedlingYield']}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Masukkan catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNurseryPicker() {
    return InkWell(
      onTap: _selectNursery,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Pilih Semaian',
          border: OutlineInputBorder(),
        ),
        child: _selectedNursery == null
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ketuk untuk memilih semaian'),
                  Icon(Icons.arrow_drop_down),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.eco, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedNursery!['seedId']?['name'] ?? 'Semaian',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
      ),
    );
  }
}
