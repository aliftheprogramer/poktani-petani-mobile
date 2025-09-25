// lib/pages/lahan/land_list_page.dart

import 'package:flutter/material.dart';
import 'package:niteni/services/api_service.dart';

class LandListPage extends StatefulWidget {
  const LandListPage({super.key});

  @override
  State<LandListPage> createState() => _LandListPageState();
}

class _LandListPageState extends State<LandListPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Panggil endpoint untuk mendapatkan daftar lahan
      final res = await _api.get('/lahan');
      final data = res.data;
      setState(() {
        // Data lahan berada di dalam key 'data'
        _items = data['data'] as List? ?? [];
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat daftar lahan';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_items.isEmpty) {
      body = const Center(child: Text('Tidak ada data lahan.'));
    } else {
      body = RefreshIndicator(
        onRefresh: _fetchLands,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _items[index] as Map<String, dynamic>;
            final name = item['name']?.toString() ?? 'Tanpa Nama';

            // Gabungkan detail lokasi untuk subtitle
            final locationDetails = [
              item['hamlet'],
              item['village'],
              item['district'],
            ].where((s) => s != null && s.isNotEmpty).join(', ');

            return Card(
              elevation: 0,
              color: const Color(0xFFEEEEEE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1),
                  child: const Icon(
                    Icons.landscape_outlined,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
                subtitle: Text(
                  locationDetails,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onTap: () {
                  // Saat item dipilih, kembali ke halaman sebelumnya dan kirim data lahan
                  Navigator.pop(context, item);
                },
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Semai'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: body),
      backgroundColor: const Color(0xFFEEEEEE),
    );
  }
}
