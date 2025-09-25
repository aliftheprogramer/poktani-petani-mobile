//detail_kegiatan_tanam.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:niteni/pages/kegiatan_tanam/pemupukan/list_pemupukan.dart';
import 'package:niteni/pages/kegiatan_tanam/penyemprotan/list_penyemprotan.dart';
import '../../services/api_service.dart';

class KegiatanTanamDetailPage extends StatefulWidget {
  final String id;
  const KegiatanTanamDetailPage({super.key, required this.id});

  @override
  State<KegiatanTanamDetailPage> createState() =>
      _KegiatanTanamDetailPageState();
}

class _KegiatanTanamDetailPageState extends State<KegiatanTanamDetailPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  final _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/kegiatantanam/${widget.id}');
      if (res.data is Map<String, dynamic>) {
        setState(() {
          _data = res.data as Map<String, dynamic>;
        });
      } else {
        _error = 'Format data tidak valid';
      }
    } catch (e) {
      _error = 'Gagal memuat detail kegiatan';
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Detail Kegiatan Tanam'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_data == null) {
      return const Center(child: Text('Data tidak ditemukan.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildFinancialCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final landData = _data!['landId'] as Map<String, dynamic>?;
    final landName = landData?['name'] ?? 'Lahan tidak diketahui';
    final status = _data!['status']?.toString() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A4F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            landName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Status: $status',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final seedData = _data!['seedId'] as Map<String, dynamic>?;
    final seedName = seedData?['name'] ?? '-';
    final seedVariety = seedData?['variety'] ?? '-';
    final plantingDate = DateTime.tryParse(_data!['plantingDate'] ?? '');
    final plantingAmount = _data!['plantingAmount']?.toString() ?? '-';
    final notes = _data!['notes']?.toString() ?? 'Tidak ada catatan.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Penanaman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.grass, 'Benih', '$seedName ($seedVariety)'),
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal Tanam',
            plantingDate != null ? _dateFormatter.format(plantingDate) : '-',
          ),
          _buildInfoRow(
            Icons.format_list_numbered,
            'Jumlah Tanam',
            '$plantingAmount bibit',
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.notes, 'Catatan', notes),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PemupukanListPage(plantingActivityId: widget.id),
                ),
              );
            },
            icon: const Icon(Icons.science_outlined, size: 20),
            label: const Text('Pemupukan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigasi ke halaman list penyemprotan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PenyemprotanListPage(
                    plantingActivityId: widget.id, // Mengirim ID kegiatan tanam
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bug_report_outlined, size: 20),
            label: const Text('Penyemprotan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard() {
    final totalCost = (_data!['totalCost'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (_data!['totalRevenue'] as num?)?.toDouble() ?? 0;
    final profit = totalRevenue - totalCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Keuangan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.arrow_downward,
            'Total Biaya',
            _currencyFormatter.format(totalCost),
            color: Colors.red,
          ),
          _buildInfoRow(
            Icons.arrow_upward,
            'Total Pendapatan',
            _currencyFormatter.format(totalRevenue),
            color: Colors.green,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            profit >= 0 ? Icons.trending_up : Icons.trending_down,
            'Estimasi Profit',
            _currencyFormatter.format(profit),
            color: profit >= 0 ? Colors.blue : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
