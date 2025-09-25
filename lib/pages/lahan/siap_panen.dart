import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SiapPanenPage extends StatefulWidget {
  final String lahanId;
  final Map<String, dynamic> lahanData;

  const SiapPanenPage({
    super.key,
    required this.lahanId,
    required this.lahanData,
  });

  @override
  State<SiapPanenPage> createState() => _SiapPanenPageState();
}

class _SiapPanenPageState extends State<SiapPanenPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _commodityController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _qualityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Quality options
  final List<String> _qualityOptions = ['A', 'B', 'C'];
  String? _selectedQuality;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _initializeData();
  }

  void _initializeData() {
    // Set commodity dari nama semai (immutable)
    final semaiList = widget.lahanData['semai'] as List? ?? [];
    if (semaiList.isNotEmpty) {
      final seedType = semaiList[0]['seedType'] as Map<String, dynamic>? ?? {};
      _commodityController.text = seedType['name'] ?? '';
    }

    // Set default harvest date ke hari ini
    _harvestDateController.text = DateTime.now().toIso8601String().split(
      'T',
    )[0];

    // Set unit ke "Kg" (immutable)
    _unitController.text = 'Kg';

    // Set default quality
    _selectedQuality = _qualityOptions[0];
    _qualityController.text = _selectedQuality!;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _harvestDateController.dispose();
    _commodityController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _qualityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _harvestDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final requestData = {
        'lahan': widget.lahanId,
        'harvestDate': '${_harvestDateController.text}T00:00:00.000Z',
        'commodity': _commodityController.text,
        'amount': int.parse(_amountController.text),
        'unit': _unitController.text,
        'quality': _selectedQuality,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      };

      final response = await _api.post('/panen', data: requestData);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Berhasil simpan data panen, sekarang clear data pupuk dan pestisida
        await _clearLahanData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Data panen berhasil disimpan dan lahan dibersihkan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Gagal menyimpan data panen');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan saat menyimpan data');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _clearLahanData() async {
    try {
      final clearResponse = await _api.put('/lahan/${widget.lahanId}/clear');

      // Log hasil clear untuk debugging (opsional)
      if (clearResponse.statusCode == 200) {
        debugPrint('Lahan data cleared successfully');
      } else {
        debugPrint('Failed to clear lahan data: ${clearResponse.statusCode}');
      }
    } catch (e) {
      // Jika clear gagal, tidak perlu mengganggu user experience
      // karena data panen sudah berhasil disimpan
      debugPrint('Error clearing lahan data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Siap Panen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildFormSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Form Panen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lahan: ${widget.lahanData['name'] ?? '-'}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Tanggal Panen',
            icon: Icons.calendar_today_rounded,
            child: TextFormField(
              controller: _harvestDateController,
              decoration: themedInput(
                'Pilih tanggal panen',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: kPrimaryColor),
                  onPressed: _selectDate,
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal panen harus diisi';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Komoditas',
            icon: Icons.eco_rounded,
            child: TextFormField(
              controller: _commodityController,
              decoration: themedInput(
                'Komoditas (otomatis dari semai)',
                suffixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                ),
              ),
              readOnly: true,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Jumlah Panen',
            icon: Icons.inventory_2_outlined,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: themedInput('Masukkan jumlah panen'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah panen harus diisi';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Jumlah panen harus berupa angka positif';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: themedInput(
                      'Satuan',
                      suffixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    readOnly: true,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Kualitas',
            icon: Icons.star_rounded,
            child: DropdownButtonFormField<String>(
              value: _selectedQuality,
              decoration: themedInput('Pilih kualitas panen'),
              items: _qualityOptions.map((quality) {
                return DropdownMenuItem<String>(
                  value: quality,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getQualityColor(quality),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            quality,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Kualitas $quality',
                        style: TextStyle(color: kTextColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value;
                  _qualityController.text = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kualitas harus dipilih';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Catatan (Opsional)',
            icon: Icons.note_alt_rounded,
            child: TextFormField(
              controller: _notesController,
              decoration: themedInput('Tambahkan catatan tentang panen...'),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _loading ? 'Menyimpan...' : 'Simpan Data Panen',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
