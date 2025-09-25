import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';

class SiapPindahPopup extends StatefulWidget {
  final String semaiId;
  const SiapPindahPopup({super.key, required this.semaiId});

  @override
  State<SiapPindahPopup> createState() => _SiapPindahPopupState();
}

class _SiapPindahPopupState extends State<SiapPindahPopup> {
  final _formKey = GlobalKey<FormState>();
  final _yieldController = TextEditingController();
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _yieldController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'status': 'Siap Pindah',
        'seedlingYield': int.tryParse(_yieldController.text) ?? 0,
        'yieldUnit': 'batang',
      };

      final response = await _api.put('/semai/${widget.semaiId}', data: data);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status semai berhasil diperbarui')),
        );
        Navigator.pop(context, true); // Return true on success
      } else {
        final errorMessage =
            response.data['message'] ?? 'Gagal memperbarui status';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pindahkan Semai'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah status menjadi "Siap Pindah" dan masukkan jumlah bibit yang dihasilkan.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _yieldController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah Bibit (Hasil)',
                hintText: 'Contoh: 100',
                suffixText: 'batang',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah bibit tidak boleh kosong';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
