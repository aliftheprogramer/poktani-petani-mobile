// seed_list_page.dart
import 'package:flutter/material.dart';
import 'package:niteni/pages/semaian/seed_semai/seed_detail_page.dart';
import '../../../services/api_service.dart';

class SeedListPage extends StatefulWidget {
  const SeedListPage({super.key});

  @override
  State<SeedListPage> createState() => _SeedListPageState();
}

class _SeedListPageState extends State<SeedListPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/benih');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['data'] as List? ?? []);
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat daftar benih';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : _items.isEmpty
        ? RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada benih',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetch,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index] as Map<String, dynamic>;
                final name = item['name']?.toString() ?? '-';
                final variety = item['variety']?.toString() ?? '';
                final price = item['price']?.toString() ?? '';
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
                      child: const Icon(Icons.grass, color: Color(0xFF2D6A4F)),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (variety.isNotEmpty) variety,
                        if (price.isNotEmpty) 'Harga: $price',
                      ].join(' • '),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      // Navigate to detail and wait for a result
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SeedDetailPage(seedId: item['_id']),
                        ),
                      );

                      if (result != null && mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                  ),
                );
              },
            ),
          );

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Pilih Benih'), centerTitle: true),
        body: SafeArea(child: body),
      ),
    );
  }
}
