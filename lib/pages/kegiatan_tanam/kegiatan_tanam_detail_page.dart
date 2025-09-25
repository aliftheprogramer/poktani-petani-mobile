//detail_kegiatan_tanam.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:niteni/pages/kegiatan_tanam/pemupukan/list_pemupukan.dart';
import 'package:niteni/pages/kegiatan_tanam/penyemprotan/list_penyemprotan.dart';
import 'package:niteni/pages/kegiatan_tanam/pemanenan/mulai_pemanenan.dart';
import 'package:niteni/pages/kegiatan_tanam/biaya_operasional/list_biaya_operasional.dart';
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
  bool _readyToHarvest = false;

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
                  _buildSourceCard(),
                  const SizedBox(height: 16),
                  _buildHarvestTimelineCard(),
                  const SizedBox(height: 16),
                  _buildOperationalCostCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildFinancialCard(),
                  const SizedBox(height: 16),
                  _buildHarvestSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalCostCard() {
    final totalOperationalCost = (_data?['operationalCost'] as num?)
        ?.toDouble();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Biaya Operasional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BiayaOperasionalListPage(
                        plantingActivityId: widget.id,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    _fetchDetail();
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalOperationalCost != null
                ? _currencyFormatter.format(totalOperationalCost)
                : 'Tambahkan biaya operasional tambahan jika ada',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Ringkasan dari semua biaya operasional tambahan',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final landData = _data?['landId'] as Map<String, dynamic>?;
    final landName = landData?['name'] ?? 'Lahan tidak diketahui';
    final status = _data?['status']?.toString() ?? 'N/A';
    final village = landData?['village'] ?? '';
    final district = landData?['district'] ?? '';
    final location = [village, district].where((s) => s.isNotEmpty).join(', ');

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.toLowerCase() == 'active'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.toLowerCase() == 'active'
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Status: $status',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final seedData = _data?['seedId'] as Map<String, dynamic>?;
    final seedName = seedData?['name'] ?? '-';
    final seedVariety = seedData?['variety'] ?? '-';
    final plantingDate = DateTime.tryParse(_data?['plantingDate'] ?? '');
    final plantingAmount = _data?['plantingAmount']?.toString() ?? '-';
    final seedUnit = seedData?['unit'] ?? '';
    final notes = _data?['notes']?.toString() ?? 'Tidak ada catatan.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2D6A4F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Penanaman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.grass,
            'Benih',
            '$seedName${seedVariety.isNotEmpty ? ' ($seedVariety)' : ''}',
            color: Colors.green,
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal Tanam',
            plantingDate != null ? _dateFormatter.format(plantingDate) : '-',
            color: Colors.blue,
          ),
          _buildInfoRow(
            Icons.format_list_numbered,
            'Jumlah Tanam',
            '$plantingAmount${seedUnit.isNotEmpty ? ' $seedUnit' : ' bibit'}',
            color: Colors.orange,
          ),
          if (notes != 'Tidak ada catatan.') ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.note_alt, 'Catatan', notes, color: Colors.grey),
          ],
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
    final totalCost = (_data?['totalCost'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (_data?['totalRevenue'] as num?)?.toDouble() ?? 0;
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

  Widget _buildSourceCard() {
    final source = _data?['source'] as Map<String, dynamic>?;
    if (source == null) return const SizedBox.shrink();

    final sourceType = source['type']?.toString() ?? '';
    final purchaseInfo = source['purchaseInfo'] as Map<String, dynamic>?;

    String sourceTitle = '';
    String sourceSubtitle = '';
    IconData sourceIcon = Icons.help;
    Color sourceColor = Colors.grey;

    switch (sourceType) {
      case 'DIRECT_PURCHASE':
        sourceTitle = 'Pembelian Langsung';
        sourceIcon = Icons.store;
        sourceColor = Colors.blue;
        if (purchaseInfo != null) {
          final supplier = purchaseInfo['supplier']?.toString() ?? '';
          final price = (purchaseInfo['price'] as num?)?.toInt() ?? 0;
          sourceSubtitle = supplier.isNotEmpty
              ? '$supplier - ${_currencyFormatter.format(price)}'
              : _currencyFormatter.format(price);
        }
        break;
      case 'FROM_NURSERY':
        sourceTitle = 'Dari Semaian';
        sourceIcon = Icons.eco;
        sourceColor = Colors.green;
        sourceSubtitle = 'Menggunakan bibit dari semaian internal';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sourceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(sourceIcon, color: sourceColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sumber Benih',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      sourceTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sourceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sourceSubtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sourceSubtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHarvestTimelineCard() {
    final seedData = _data?['seedId'] as Map<String, dynamic>?;
    final daysToHarvest = (seedData?['days_to_harvest'] as num?)?.toInt() ?? 0;
    final plantingDate = DateTime.tryParse(_data?['plantingDate'] ?? '');

    if (plantingDate == null || daysToHarvest <= 0) {
      return const SizedBox.shrink();
    }

    final harvestDate = plantingDate.add(Duration(days: daysToHarvest));
    final now = DateTime.now();
    final daysElapsed = now.difference(plantingDate).inDays;
    final daysRemaining = harvestDate.difference(now).inDays;
    final progress = (daysElapsed / daysToHarvest).clamp(0.0, 1.0);

    String statusText = '';
    Color progressColor = Colors.green;

    if (daysRemaining > 0) {
      statusText = '$daysRemaining hari lagi menuju panen';
      progressColor = Colors.orange;
    } else if (daysRemaining == 0) {
      statusText = 'Hari ini adalah waktu panen!';
      progressColor = Colors.green;
    } else {
      statusText = 'Sudah lewat ${-daysRemaining} hari dari waktu panen';
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.schedule, color: progressColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeline Panen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hari ${daysElapsed.clamp(0, daysToHarvest)} dari $daysToHarvest',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  daysRemaining <= 0 ? Icons.celebration : Icons.access_time,
                  size: 16,
                  color: progressColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Perkiraan siap panen: ${_dateFormatter.format(harvestDate)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Panen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: CheckboxListTile(
              value: _readyToHarvest,
              onChanged: (bool? value) {
                setState(() {
                  _readyToHarvest = value ?? false;
                });
              },
              title: const Text(
                'Saya yakin tanaman sudah siap dipanen',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Centang untuk mengaktifkan tombol panen',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Harvest button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _readyToHarvest ? _showHarvestDialog : null,
              icon: Icon(
                Icons.agriculture,
                size: 20,
                color: _readyToHarvest ? Colors.white : Colors.grey[400],
              ),
              label: Text(
                'Mulai Panen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _readyToHarvest ? Colors.white : Colors.grey[400],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _readyToHarvest
                    ? Colors.green
                    : Colors.grey[300],
                elevation: _readyToHarvest ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!_readyToHarvest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '💡 Centang kotak di atas untuk mengaktifkan tombol panen',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _showHarvestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.agriculture,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Panen'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin memulai proses panen untuk kegiatan tanam ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to harvest page
              if (mounted) {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MulaiPemanenanPage(
                      kegiatanTanamId: widget.id,
                      kegiatanTanamData: _data,
                    ),
                  ),
                );

                // If harvest was successful, refresh the detail page
                if (result == true && mounted) {
                  _fetchDetail();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Mulai Panen'),
          ),
        ],
      ),
    );
  }
}
