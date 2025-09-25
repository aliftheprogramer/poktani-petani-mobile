// seed_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class SeedDetailPage extends StatefulWidget {
  final String seedId;

  const SeedDetailPage({super.key, required this.seedId});

  @override
  State<SeedDetailPage> createState() => _SeedDetailPageState();
}

class _SeedDetailPageState extends State<SeedDetailPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _seed;

  @override
  void initState() {
    super.initState();
    _fetchSeedDetail();
  }

  Future<void> _fetchSeedDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/benih/${widget.seedId}');
      setState(() {
        _seed = res.data as Map<String, dynamic>?;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat detail benih';
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
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchSeedDetail,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    } else if (_seed == null) {
      body = const Center(child: Text('Data benih tidak ditemukan.'));
    } else {
      body = _buildSeedDetails();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_seed?['name'] ?? 'Detail Benih'),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: _seed == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    // Pop the page and return the seed data
                    Navigator.pop(context, _seed);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Pilih Benih Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSeedDetails() {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final imageUrl = _seed!['image_url'] as String?;
    final name = _seed!['name']?.toString() ?? '-';
    final variety = _seed!['variety']?.toString() ?? '-';
    final price = _seed!['price'] != null
        ? formatCurrency.format(_seed!['price'])
        : '-';
    final stock = _seed!['stock']?.toString() ?? '-';
    final unit = _seed!['unit']?.toString() ?? '';
    final description =
        _seed!['description']?.toString() ?? 'Tidak ada deskripsi.';
    final daysToHarvest = _seed!['days_to_harvest']?.toString() ?? '-';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Varietas: $variety',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'Stok',
                  '$stock $unit',
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.schedule_outlined,
                  'Panen dalam',
                  '$daysToHarvest hari',
                ),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
