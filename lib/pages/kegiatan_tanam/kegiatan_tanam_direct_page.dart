import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../semaian/seed_semai/seed_list_page.dart';

class KegiatanTanamDirectPage extends StatefulWidget {
  final String landId;
  const KegiatanTanamDirectPage({super.key, required this.landId});

  @override
  State<KegiatanTanamDirectPage> createState() =>
      _KegiatanTanamDirectPageState();
}

class _KegiatanTanamDirectPageState extends State<KegiatanTanamDirectPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _seedCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _totalCostCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  Map<String, dynamic>? _selectedSeed;
  bool _isSubmitting = false;
  DateTime _plantingDate = DateTime.now();

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _formatYMD(_plantingDate);
    _amountCtrl.addListener(_recalculateTotal);
    _priceCtrl.addListener(_recalculateTotal);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_recalculateTotal);
    _priceCtrl.removeListener(_recalculateTotal);
    _seedCtrl.dispose();
    _amountCtrl.dispose();
    _supplierCtrl.dispose();
    _priceCtrl.dispose();
    _totalCostCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _formatYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _recalculateTotal() {
    final qty = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final total = qty * price;
    _totalCostCtrl.text = total.toString();
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
        // Prefill price if seed has price
        final seedPrice = (result['price'] as num?)?.toInt();
        if (seedPrice != null && seedPrice > 0) {
          _priceCtrl.text = seedPrice.toString();
        }
        _recalculateTotal();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _plantingDate = picked;
        _dateCtrl.text = _formatYMD(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSeed == null || _selectedSeed!['_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih benih terlebih dahulu.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final payload = {
      'landId': widget.landId,
      'seedId': _selectedSeed!['_id'],
      'plantingDate': _dateCtrl.text,
      'plantingAmount': int.tryParse(_amountCtrl.text.trim()) ?? 0,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'source': {
        'type': 'DIRECT_PURCHASE',
        'purchaseInfo': {
          'supplier': _supplierCtrl.text.trim(),
          'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
          'totalCost': int.tryParse(_totalCostCtrl.text.trim()) ?? 0,
        },
      },
    };

    try {
      await _api.post('/kegiatantanam', data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Kegiatan tanam berhasil dibuat.')),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String message = 'Gagal membuat kegiatan tanam';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _dec({
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tanam Langsung'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // BENIH
                  _SectionCard(
                    title: 'Informasi Benih',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _seedCtrl,
                          readOnly: true,
                          decoration: _dec(
                            label: 'Benih',
                            prefixIcon: const Icon(
                              Icons.grass,
                              color: Color(0xFF2D6A4F),
                            ),
                            suffixIcon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          ),
                          onTap: _pickSeed,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Wajib pilih benih'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountCtrl,
                                decoration: _dec(
                                  label: 'Jumlah',
                                  prefixIcon: const Icon(
                                    Icons.format_list_numbered,
                                    color: Color(0xFF2D6A4F),
                                  ),
                                  hint: 'Misal 100',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wajib';
                                  final val = int.tryParse(v);
                                  if (val == null || val <= 0)
                                    return 'Angka > 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 140,
                              child: TextFormField(
                                controller: _priceCtrl,
                                decoration: _dec(
                                  label: 'Harga Satuan',
                                  prefixIcon: const Icon(
                                    Icons.payments_outlined,
                                    color: Color(0xFF2D6A4F),
                                  ),
                                  hint: 'Rp',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wajib';
                                  final val = int.tryParse(v);
                                  if (val == null || val < 0) return '>= 0';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _totalCostCtrl,
                          enabled: false,
                          decoration: _dec(
                            label: 'Total Biaya (Qty x Harga)',
                            prefixIcon: const Icon(
                              Icons.calculate,
                              color: Color(0xFF2D6A4F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TANAM
                  _SectionCard(
                    title: 'Detail Penanaman',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          decoration: _dec(
                            label: 'Tanggal Tanam',
                            prefixIcon: const Icon(
                              Icons.event,
                              color: Color(0xFF2D6A4F),
                            ),
                            hint: 'Pilih tanggal',
                          ),
                          onTap: _pickDate,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // SUMBER
                  _SectionCard(
                    title: 'Sumber (Pembelian Langsung)',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _supplierCtrl,
                          decoration: _dec(
                            label: 'Supplier / Toko',
                            prefixIcon: const Icon(
                              Icons.storefront_outlined,
                              color: Color(0xFF2D6A4F),
                            ),
                            hint: 'Contoh: Toko Tani Jaya',
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CATATAN
                  _SectionCard(
                    title: 'Catatan',
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: _dec(
                        label: 'Catatan (opsional)',
                        prefixIcon: const Icon(
                          Icons.note_alt_outlined,
                          color: Color(0xFF2D6A4F),
                        ),
                        hint: 'Contoh: Penanaman musim kedua...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Menyimpan...'
                            : 'Simpan Kegiatan Tanam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Batal'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D6A4F),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
