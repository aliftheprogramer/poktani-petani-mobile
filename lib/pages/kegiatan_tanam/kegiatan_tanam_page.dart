import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'kegiatan_tanam_detail_page.dart';
import 'kegiatan_tanam_add_page.dart';

class KegiatanTanamPage extends StatefulWidget {
  final String? landId;
  const KegiatanTanamPage({super.key, this.landId});

  @override
  State<KegiatanTanamPage> createState() => _KegiatanTanamPageState();
}

class _KegiatanTanamPageState extends State<KegiatanTanamPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _kegiatanTanam = [];
  final DateFormat _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _fetchKegiatanTanam();
  }

  Future<void> _fetchKegiatanTanam() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String url = '/kegiatantanam';
      if (widget.landId != null) {
        url += '?landId=${widget.landId}';
      }
      final res = await _api.get(url);
      if (res.data is Map<String, dynamic> && res.data['data'] is List) {
        setState(() {
          _kegiatanTanam = res.data['data'];
        });
      } else {
        _error = 'Format data tidak sesuai';
      }
    } catch (e) {
      _error = 'Gagal memuat kegiatan tanam';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.landId != null
                ? 'Kegiatan Tanam Lahan'
                : 'Semua Kegiatan Tanam',
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
        floatingActionButton: widget.landId == null
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KegiatanTanamAddPage(landId: widget.landId!),
                    ),
                  );
                  if (result == true) {
                    _fetchKegiatanTanam();
                    setState(() => _changed = true);
                  }
                },
                backgroundColor: const Color(0xFF2D6A4F),
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchKegiatanTanam,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_kegiatanTanam.isEmpty) {
      return const Center(child: Text('Tidak ada kegiatan tanam.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchKegiatanTanam,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _kegiatanTanam.length,
        itemBuilder: (context, index) {
          final kegiatan = _kegiatanTanam[index];
          final seedData = kegiatan['seedId'] as Map<String, dynamic>?;
          final seedName = seedData?['name'] ?? 'Benih tidak diketahui';
          final landData = kegiatan['landId'] as Map<String, dynamic>?;
          final landName = landData?['name'] ?? 'Lahan tidak diketahui';
          final plantingDateStr = kegiatan['plantingDate'] as String?;
          String formattedDate = 'Tanggal tidak diketahui';
          if (plantingDateStr != null) {
            final plantingDate = DateTime.tryParse(plantingDateStr);
            if (plantingDate != null) {
              formattedDate = _dateFormatter.format(plantingDate);
            }
          }
          final status = kegiatan['status'] ?? 'N/A';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        KegiatanTanamDetailPage(id: kegiatan['_id']),
                  ),
                );
                if (result == true) {
                  _fetchKegiatanTanam();
                  setState(() => _changed = true);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            seedName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status == 'Active'
                                  ? Colors.green.shade800
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.terrain, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(landName),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(formattedDate),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
