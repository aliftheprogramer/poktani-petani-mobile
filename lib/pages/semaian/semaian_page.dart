//semaian_page.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widget/item_semaian.dart';
import 'semaian_detail_page.dart';
import 'semaian_add_page.dart';

class SemaianPage extends StatefulWidget {
  final bool isSelectionMode;
  const SemaianPage({super.key, this.isSelectionMode = false});

  @override
  State<SemaianPage> createState() => _SemaianPageState();
}

class _SemaianPageState extends State<SemaianPage> {
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchSemai();
  }

  Future<void> _fetchSemai() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/semai');
      final data = res.data;
      if (data is Map && data['data'] is List) {
        _items = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      } else if (data is List) {
        _items = data.whereType<Map<String, dynamic>>().toList(growable: false);
      } else {
        _items = [];
      }
    } catch (e) {
      _error = 'Gagal memuat data';
      _items = [];
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Semaian', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: const Color(0xFFEEEEEE),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? RefreshIndicator(
                  onRefresh: _fetchSemai,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
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
                  onRefresh: _fetchSemai,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data semai.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol + untuk menambah semai baru',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSemai,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final id = item['_id']?.toString();
                      return ItemSemai(
                        data: item,
                        onTap: id == null
                            ? null
                            : () async {
                                if (widget.isSelectionMode) {
                                  Navigator.pop(context, item);
                                } else {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SemaianDetailPage(id: id),
                                    ),
                                  );
                                  if (changed == true) {
                                    await _fetchSemai();
                                  }
                                }
                              },
                      );
                    },
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const SemaianAddPage()),
            );
            if (created == true) {
              await _fetchSemai();
            }
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
