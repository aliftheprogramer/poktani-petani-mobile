import 'package:flutter/material.dart';
import 'package:niteni/pages/kegiatan_tanam/pemupukan/add_pemupukan.dart';
import 'package:niteni/pages/kegiatan_tanam/pemupukan/widget/item_pemupukan.dart';
import 'package:niteni/services/api_service.dart';

class PemupukanListPage extends StatefulWidget {
  final String plantingActivityId;

  const PemupukanListPage({super.key, required this.plantingActivityId});

  @override
  State<PemupukanListPage> createState() => _PemupukanListPageState();
}

class _PemupukanListPageState extends State<PemupukanListPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _listData = [];

  @override
  void initState() {
    super.initState();
    _fetchPemupukan();
  }

  Future<void> _fetchPemupukan() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get(
        '/kegiatantanam/${widget.plantingActivityId}/pemupukan',
      );
      if (res.data is List) {
        setState(() {
          _listData = res.data as List;
        });
      } else {
        _error = 'Format data tidak valid.';
      }
    } catch (e) {
      _error = 'Gagal memuat data pemupukan.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Riwayat Pemupukan'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PemupukanAddPage(
                plantingActivityId: widget.plantingActivityId,
              ),
            ),
          );
          if (result == true) {
            _fetchPemupukan();
          }
        },
        label: const Text('Tambah'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.orange.shade700),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPemupukan,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_listData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 60, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data pemupukan.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPemupukan,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _listData.length,
        itemBuilder: (context, index) {
          final item = _listData[index] as Map<String, dynamic>;
          return PemupukanListItem(item: item);
        },
      ),
    );
  }
}
