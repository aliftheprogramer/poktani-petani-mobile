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
  String? _landName; // Derived from first item when filtering by land
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
        // Original list returned from API
        final originalList = (res.data['data'] as List);
        // Filter: hanya tampilkan yang statusnya 'Active'
        final list = originalList
            .where(
              (item) =>
                  ((item as Map<String, dynamic>)['status'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  'active',
            )
            .toList();
        setState(() {
          _kegiatanTanam = list;
          // Try to derive land name for AppBar if filtered by land
          // Use the original list for deriving land name in case all items are filtered out
          if (widget.landId != null && originalList.isNotEmpty) {
            final first = originalList.first as Map<String, dynamic>;
            final land = first['landId'] as Map<String, dynamic>?;
            _landName = land?['name']?.toString();
          }
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
                ? (_landName != null
                      ? 'Kegiatan Tanam $_landName'
                      : 'Kegiatan Tanam')
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
          final seedVariety = seedData?['variety']?.toString();
          final plantingDateStr = kegiatan['plantingDate'] as String?;
          String formattedDate = 'Tanggal tidak diketahui';
          if (plantingDateStr != null) {
            final plantingDate = DateTime.tryParse(plantingDateStr);
            if (plantingDate != null) {
              formattedDate = _dateFormatter.format(plantingDate);
            }
          }
          final status = kegiatan['status'] ?? 'N/A';
          final totalCost = (kegiatan['totalCost'] as num?)?.toDouble() ?? 0;
          final totalRevenue =
              (kegiatan['totalRevenue'] as num?)?.toDouble() ?? 0;
          final profit = totalRevenue - totalCost;
          final source = kegiatan['source'] as Map<String, dynamic>?;
          final sourceType = source?['type']?.toString();
          IconData sourceIcon = Icons.help_outline;
          Color sourceColor = Colors.grey;
          if (sourceType == 'DIRECT_PURCHASE') {
            sourceIcon = Icons.store;
            sourceColor = Colors.blue;
          } else if (sourceType == 'FROM_NURSERY') {
            sourceIcon = Icons.eco;
            sourceColor = Colors.green;
          }

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sourceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(sourceIcon, color: sourceColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      seedVariety != null &&
                                              seedVariety.isNotEmpty
                                          ? '$seedName ($seedVariety)'
                                          : seedName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusChip(status: status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.arrow_downward,
                          color: Colors.red,
                          label: 'Biaya',
                          value: _currencyFormatter.format(totalCost),
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                          label: 'Pendapatan',
                          value: _currencyFormatter.format(totalRevenue),
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: profit >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: profit >= 0 ? Colors.blue : Colors.orange,
                          label: 'Profit',
                          value: _currencyFormatter.format(profit),
                        ),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'active':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'harvested':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade800;
        break;
      case 'pending':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade800;
        break;
      case 'failed':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
