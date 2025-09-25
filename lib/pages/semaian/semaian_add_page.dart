// semaian_add_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'seed_semai/seed_list_page.dart';

class SemaianAddPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? editId;

  const SemaianAddPage({super.key, this.initialData, this.editId});

  @override
  State<SemaianAddPage> createState() => _SemaianAddPageState();
}

class _SemaianAddPageState extends State<SemaianAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _seedCtrl = TextEditingController();
  final _seedAmountCtrl = TextEditingController();
  final _seedUnitCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _additionalCostCtrl = TextEditingController();
  final _nurseryLocationCtrl = TextEditingController();

  Map<String, dynamic>? _selectedSeed;
  bool _submitting = false;

  final ApiService _api = ApiService();

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _seedAmountCtrl.addListener(_calculateCost);
    _additionalCostCtrl.text = _currencyFormatter.format(0);

    final init = widget.initialData;
    if (init != null) {
      final st = (init['seedType'] as Map<String, dynamic>?) ?? {};
      if (st.isNotEmpty) {
        _selectedSeed = {
          '_id': st['_id'],
          'name': st['name'],
          'variety': st['variety'],
          'price': st['price'],
          'unit': init['seedUnit'],
          'days_to_harvest': st['days_to_harvest'], // Pastikan ini ada
        };
        final name = _selectedSeed!['name']?.toString() ?? '';
        final variety = _selectedSeed!['variety']?.toString() ?? '';
        _seedCtrl.text = variety.isNotEmpty ? '$name ($variety)' : name;
        _seedUnitCtrl.text = _selectedSeed!['unit']?.toString() ?? '';
      }

      final amount = init['seedAmount'];
      if (amount != null) {
        _seedAmountCtrl.text = amount.toString();
      }

      _calculateCost();

      final locationData = init['nurseryLocation'];
      if (locationData != null) {
        if (locationData is Map<String, dynamic>) {
          _nurseryLocationCtrl.text = locationData['name'] ?? '';
        } else {
          _nurseryLocationCtrl.text = locationData.toString();
        }
      }

      final sd = init['startDate']?.toString();
      if (sd != null && sd.isNotEmpty) {
        final dt = DateTime.tryParse(sd);
        _startDateCtrl.text = dt != null ? _formatYMD(dt) : sd;
      }
      final ed =
          init['estimatedReadyDate']?.toString() ?? init['endDate']?.toString();
      if (ed != null && ed.isNotEmpty) {
        final dt = DateTime.tryParse(ed);
        _endDateCtrl.text = dt != null ? _formatYMD(dt) : ed;
      }

      final notes = init['notes']?.toString();
      if (notes != null) _notesCtrl.text = notes;
    }
  }

  @override
  void dispose() {
    _seedAmountCtrl.removeListener(_calculateCost);
    _seedCtrl.dispose();
    _seedAmountCtrl.dispose();
    _seedUnitCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _notesCtrl.dispose();
    _additionalCostCtrl.dispose();
    _nurseryLocationCtrl.dispose();
    super.dispose();
  }

  void _calculateCost() {
    final amount = double.tryParse(_seedAmountCtrl.text) ?? 0;
    final price = (_selectedSeed?['price'] as num?)?.toDouble() ?? 0.0;
    final totalCost = amount * price;
    _additionalCostCtrl.text = _currencyFormatter.format(totalCost);
  }

  // BARU: Fungsi untuk menghitung tanggal selesai/panen secara otomatis
  void _calculateEndDate() {
    // Pastikan benih sudah dipilih dan tanggal mulai sudah diisi
    if (_selectedSeed == null || _startDateCtrl.text.isEmpty) {
      return;
    }

    // Ambil nilai days_to_harvest dari data benih yang dipilih
    // Lakukan pengecekan tipe data untuk keamanan
    final daysToHarvest = _selectedSeed!['days_to_harvest'] as int?;

    // Jika tidak ada data hari panen, jangan lakukan apa-apa
    if (daysToHarvest == null || daysToHarvest <= 0) {
      _endDateCtrl.clear(); // Bersihkan field jika tidak ada data panen
      return;
    }

    // Parse tanggal mulai menjadi objek DateTime
    final startDate = _parseYMD(_startDateCtrl.text);
    if (startDate == null) {
      return;
    }

    // Hitung tanggal selesai dengan menambahkan durasi hari panen
    final endDate = startDate.add(Duration(days: daysToHarvest));

    // Set nilai controller dengan tanggal yang sudah diformat
    _endDateCtrl.text = _formatYMD(endDate);
  }

  String _formatYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseYMD(String s) {
    try {
      final parts = s.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickSeed() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SeedListPage()),
    );
    if (result != null) {
      setState(() {
        _selectedSeed = result;
        final name = result['name']?.toString() ?? '';
        final variety = result['variety']?.toString() ?? '';
        _seedCtrl.text = variety.isNotEmpty ? '$name ($variety)' : name;
        _seedUnitCtrl.text = result['unit']?.toString() ?? '';
        _calculateCost();
      });
      // MODIFIKASI: Panggil fungsi kalkulasi setelah memilih benih
      _calculateEndDate();
    }
  }

  Future<void> _pickStartDate() async {
    final current = _parseYMD(_startDateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _startDateCtrl.text = _formatYMD(picked);
      // MODIFIKASI: Panggil fungsi kalkulasi setelah memilih tanggal mulai
      _calculateEndDate();
      // setState tidak wajib di sini karena _calculateEndDate sudah mengubah controller,
      // tapi jika ada UI lain yang bergantung pada tanggal, biarkan saja.
      setState(() {});
    }
  }

  Future<void> _pickEndDate() async {
    final start = _parseYMD(_startDateCtrl.text);
    final initial = _parseYMD(_endDateCtrl.text) ?? start ?? DateTime.now();
    final first = start ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _endDateCtrl.text = _formatYMD(picked);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSeed == null || _selectedSeed!['_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih benih terlebih dahulu')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final amount = int.tryParse(_seedAmountCtrl.text) ?? 0;
      final price = (_selectedSeed!['price'] as num?)?.toInt() ?? 0;
      final cost = amount * price;

      final payload = {
        'seedId': _selectedSeed!['_id'],
        'seedAmount': amount,
        'seedUnit': _seedUnitCtrl.text,
        'startDate': _startDateCtrl.text,
        'estimatedReadyDate': _endDateCtrl.text,
        'nurseryLocation': _nurseryLocationCtrl.text,
        'additionalCost': cost,
        'notes': _notesCtrl.text,
      };

      final res = widget.editId == null
          ? await _api.post('/semai', data: payload)
          : await _api.put('/semai/${widget.editId}', data: payload);

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editId == null
                  ? 'Berhasil menambahkan semai'
                  : 'Berhasil memperbarui semai',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editId == null
                  ? 'Gagal menambahkan semai (${res.statusCode})'
                  : 'Gagal memperbarui semai (${res.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menyimpan')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editId == null ? 'Tambah Semai' : 'Edit Semai'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    color: const Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Benih',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D6A4F),
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _seedCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Benih',
                              prefixIcon: Icon(
                                Icons.grass,
                                color: Color(0xFF2D6A4F),
                              ),
                              suffixIcon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                            ),
                            onTap: _pickSeed,
                            validator: (v) =>
                                v!.isEmpty ? 'Wajib pilih benih' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _seedAmountCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah Benih',
                                    prefixIcon: Icon(
                                      Icons.scale,
                                      color: Color(0xFF2D6A4F),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  controller: _seedUnitCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Satuan',
                                  ),
                                  enabled: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _additionalCostCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Biaya Tambahan (Otomatis)',
                              prefixIcon: Icon(
                                Icons.monetization_on,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: const Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Semai',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D6A4F),
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _startDateCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Mulai',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                            onTap: _pickStartDate,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _endDateCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Perkiraan Siap Pindah Tanam',
                              // MODIFIKASI: Tambahkan helperText untuk kejelasan
                              helperText:
                                  'Otomatis dihitung dari tanggal mulai & benih',
                              prefixIcon: Icon(
                                Icons.event,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                            onTap:
                                _pickEndDate, // Tetap ada jika user mau override manual
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi';
                              final start = _parseYMD(_startDateCtrl.text);
                              final end = _parseYMD(v);
                              if (start != null &&
                                  end != null &&
                                  end.isBefore(start)) {
                                return 'Tidak boleh sebelum tanggal mulai';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: const Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Lainnya',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D6A4F),
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nurseryLocationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lokasi Semai',
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Wajib isi lokasi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Catatan Tambahan',
                              prefixIcon: Icon(
                                Icons.note,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _submitting ? 'Menyimpan...' : 'Simpan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
