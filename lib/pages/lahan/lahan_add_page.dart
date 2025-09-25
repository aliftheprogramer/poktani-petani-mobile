import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LahanAddPage extends StatefulWidget {
  final Map<String, dynamic>? initialData; // if provided, acts as edit form
  final String? editId; // id for PUT /lahan/{id}

  const LahanAddPage({super.key, this.initialData, this.editId});

  @override
  State<LahanAddPage> createState() => _LahanAddPageState();
}

class _LahanAddPageState extends State<LahanAddPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _landAreaCtrl = TextEditingController();
  final _soilTypeCtrl = TextEditingController();
  final _hamletCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  bool _submitting = false;
  final ApiService _api = ApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    final init = widget.initialData;
    if (init != null) {
      _nameCtrl.text = init['name']?.toString() ?? '';
      final la = init['landArea'];
      if (la != null) _landAreaCtrl.text = la.toString();
      _soilTypeCtrl.text = init['soilType']?.toString() ?? '';
      _hamletCtrl.text = init['hamlet']?.toString() ?? '';
      _villageCtrl.text = init['village']?.toString() ?? '';
      _districtCtrl.text = init['district']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameCtrl.dispose();
    _landAreaCtrl.dispose();
    _soilTypeCtrl.dispose();
    _hamletCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final landAreaVal = int.tryParse(_landAreaCtrl.text.trim());
      final payload = {
        'name': _nameCtrl.text.trim(),
        'landArea': landAreaVal ?? _landAreaCtrl.text.trim(),
        'soilType': _soilTypeCtrl.text.trim(),
        'hamlet': _hamletCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
      };

      final res = widget.editId == null
          ? await _api.post('/lahan', data: payload)
          : await _api.put('/lahan/${widget.editId}', data: payload);
      if (!mounted) return;
      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.editId == null
                      ? 'Lahan berhasil ditambahkan'
                      : 'Lahan berhasil diperbarui',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
        _showErrorSnackBar(
          widget.editId == null
              ? 'Gagal menambahkan lahan (${res.statusCode})'
              : 'Gagal memperbarui lahan (${res.statusCode})',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan saat menyimpan data');
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
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
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: Text(
          widget.editId == null ? 'Tambah Lahan' : 'Edit Lahan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
          colors: [kPrimaryColor.withOpacity(0.1), Colors.green.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.editId == null ? 'Tambah Lahan Baru' : 'Edit Data Lahan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.editId == null
                ? 'Lengkapi informasi lahan yang akan ditambahkan'
                : 'Perbarui informasi lahan yang diperlukan',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
          Text(
            'Informasi Lahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Nama Lahan',
            icon: Icons.landscape_rounded,
            child: TextFormField(
              controller: _nameCtrl,
              decoration: themedInput('Masukkan nama lahan'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama lahan harus diisi'
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Luas Lahan',
            icon: Icons.square_foot_rounded,
            child: TextFormField(
              controller: _landAreaCtrl,
              decoration: themedInput('Masukkan luas lahan (m²)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Luas lahan harus diisi'
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Jenis Tanah',
            icon: Icons.terrain_rounded,
            child: TextFormField(
              controller: _soilTypeCtrl,
              decoration: themedInput('Masukkan jenis tanah'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Jenis tanah harus diisi'
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Informasi Lokasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Dusun',
            icon: Icons.location_on_rounded,
            child: TextFormField(
              controller: _hamletCtrl,
              decoration: themedInput('Masukkan nama dusun'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Dusun harus diisi' : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Desa',
            icon: Icons.home_work_rounded,
            child: TextFormField(
              controller: _villageCtrl,
              decoration: themedInput('Masukkan nama desa'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Desa harus diisi' : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Kecamatan',
            icon: Icons.business_rounded,
            child: TextFormField(
              controller: _districtCtrl,
              decoration: themedInput('Masukkan nama kecamatan'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Kecamatan harus diisi'
                  : null,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                widget.editId == null ? Icons.add_rounded : Icons.save_rounded,
                size: 20,
              ),
        label: Text(
          _submitting
              ? 'Menyimpan...'
              : widget.editId == null
              ? 'Tambah Lahan'
              : 'Simpan Perubahan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
