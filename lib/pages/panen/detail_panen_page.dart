import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailPanenPage extends StatefulWidget {
  final String kegiatanTanamId;
  final Map<String, dynamic> kegiatanTanamData;

  const DetailPanenPage({
    super.key,
    required this.kegiatanTanamId,
    required this.kegiatanTanamData,
  });

  @override
  State<DetailPanenPage> createState() => _DetailPanenPageState();
}

class _DetailPanenPageState extends State<DetailPanenPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _harvestData = [];

  final DateFormat _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  final DateFormat _dateTimeFormatter = DateFormat(
    'd MMMM yyyy, HH:mm',
    'id_ID',
  );
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchHarvestDetail();
  }

  Future<void> _fetchHarvestDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get(
        '/kegiatantanam/${widget.kegiatanTanamId}/panen',
      );
      if (res.data is List) {
        setState(() {
          _harvestData = res.data as List;
        });
      } else {
        _error = 'Format data tidak sesuai';
      }
    } catch (e) {
      _error = 'Gagal memuat detail panen';
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
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Detail Panen'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHarvestDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_harvestData.isEmpty) {
      return const Center(child: Text('Tidak ada data panen'));
    }

    return RefreshIndicator(
      onRefresh: _fetchHarvestDetail,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPlantingInfoCard(),
                  const SizedBox(height: 16),
                  ..._harvestData.map(
                    (harvest) => Column(
                      children: [
                        _buildHarvestDetailCard(harvest),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  _buildSummaryCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final seedData =
        widget.kegiatanTanamData['seedId'] as Map<String, dynamic>?;
    final landData =
        widget.kegiatanTanamData['landId'] as Map<String, dynamic>?;
    final seedName = seedData?['name'] ?? 'Tanaman tidak diketahui';
    final seedVariety = seedData?['variety']?.toString();
    final landName = landData?['name'] ?? 'Lahan tidak diketahui';

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
                  Icons.agriculture,
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
                      seedVariety != null && seedVariety.isNotEmpty
                          ? '$seedName ($seedVariety)'
                          : seedName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lahan: $landName',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
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
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Panen Selesai',
                  style: TextStyle(
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

  Widget _buildPlantingInfoCard() {
    final plantingDateStr = widget.kegiatanTanamData['plantingDate'] as String?;
    final plantingAmount =
        widget.kegiatanTanamData['plantingAmount']?.toString() ?? '0';

    String plantingDate = 'Tanggal tidak diketahui';
    if (plantingDateStr != null) {
      final date = DateTime.tryParse(plantingDateStr);
      if (date != null) {
        plantingDate = _dateFormatter.format(date);
      }
    }

    return _buildCard(
      title: 'Informasi Penanaman',
      icon: Icons.eco,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal Tanam',
            plantingDate,
            color: Colors.blue,
          ),
          _buildInfoRow(
            Icons.format_list_numbered,
            'Jumlah Bibit',
            '$plantingAmount bibit',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestDetailCard(Map<String, dynamic> harvest) {
    final harvestDateStr = harvest['harvestDate'] as String?;
    final saleType = harvest['saleType']?.toString() ?? '';
    final amount = harvest['amount']?.toString() ?? '0';
    final unit = harvest['unit']?.toString() ?? 'kg';
    final quality = harvest['quality']?.toString() ?? '';
    final sellingPrice = (harvest['sellingPrice'] as num?)?.toDouble() ?? 0;
    final harvestCost = (harvest['harvestCost'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (harvest['totalRevenue'] as num?)?.toDouble() ?? 0;
    final saleStatus = harvest['saleStatus']?.toString() ?? 'Belum Terjual';
    final createdAtStr = harvest['createdAt'] as String?;

    String harvestDate = 'Tanggal tidak diketahui';
    String recordedAt = 'Tanggal tidak diketahui';

    if (harvestDateStr != null) {
      final date = DateTime.tryParse(harvestDateStr);
      if (date != null) {
        harvestDate = _dateFormatter.format(date);
      }
    }

    if (createdAtStr != null) {
      final date = DateTime.tryParse(createdAtStr);
      if (date != null) {
        recordedAt = _dateTimeFormatter.format(date);
      }
    }

    Color qualityColor;
    switch (quality.toLowerCase()) {
      case 'a':
        qualityColor = Colors.green;
        break;
      case 'b':
        qualityColor = Colors.orange;
        break;
      case 'c':
        qualityColor = Colors.red;
        break;
      default:
        qualityColor = Colors.grey;
    }

    return _buildCard(
      title: 'Detail Panen',
      icon: Icons.agriculture,
      iconColor: Colors.green,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal Panen',
            harvestDate,
            color: Colors.blue,
          ),
          _buildInfoRow(
            Icons.access_time,
            'Dicatat Pada',
            recordedAt,
            color: Colors.grey,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.sell,
            'Jenis Penjualan',
            saleType,
            color: Colors.purple,
          ),
          _buildInfoRow(
            Icons.scale,
            'Jumlah Panen',
            '$amount $unit',
            color: Colors.green,
          ),
          _buildInfoRow(
            Icons.stars,
            'Kualitas',
            'Kualitas $quality',
            color: qualityColor,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.attach_money,
            'Harga Jual per $unit',
            _currencyFormatter.format(sellingPrice),
            color: Colors.green,
          ),
          _buildInfoRow(
            Icons.money_off,
            'Biaya Panen',
            _currencyFormatter.format(harvestCost),
            color: Colors.red,
          ),
          _buildInfoRow(
            Icons.account_balance_wallet,
            'Total Pendapatan',
            _currencyFormatter.format(totalRevenue),
            color: const Color(0xFF2D6A4F),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.inventory, size: 20, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Penjualan',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: saleStatus == 'Terjual'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        saleStatus,
                        style: TextStyle(
                          color: saleStatus == 'Terjual'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalCost =
        (widget.kegiatanTanamData['totalCost'] as num?)?.toDouble() ?? 0;
    final totalRevenue =
        (widget.kegiatanTanamData['totalRevenue'] as num?)?.toDouble() ?? 0;
    final profit = totalRevenue - totalCost;

    // Calculate total harvest amount
    final totalHarvestAmount = _harvestData.fold<double>(
      0,
      (sum, harvest) => sum + ((harvest['amount'] as num?)?.toDouble() ?? 0),
    );

    return _buildCard(
      title: 'Ringkasan Keseluruhan',
      icon: Icons.summarize,
      iconColor: Colors.indigo,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.scale,
            'Total Hasil Panen',
            '${totalHarvestAmount.toStringAsFixed(0)} kg',
            color: Colors.green,
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
          _buildInfoRow(
            profit >= 0 ? Icons.trending_up : Icons.trending_down,
            profit >= 0 ? 'Total Keuntungan' : 'Total Kerugian',
            _currencyFormatter.format(profit.abs()),
            color: profit >= 0 ? Colors.blue : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: color ?? Colors.black87,
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
