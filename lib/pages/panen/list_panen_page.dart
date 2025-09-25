import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'detail_panen_page.dart';

class ListPanenPage extends StatefulWidget {
  const ListPanenPage({super.key});

  @override
  State<ListPanenPage> createState() => _ListPanenPageState();
}

class _ListPanenPageState extends State<ListPanenPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _harvestedActivities = [];

  final DateFormat _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchHarvestedActivities();
  }

  Future<void> _fetchHarvestedActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/kegiatantanam');
      if (res.data is Map<String, dynamic> && res.data['data'] is List) {
        final allActivities = res.data['data'] as List;
        // Filter activities with status "Harvested" or "Failed"
        final completedActivities = allActivities
            .where(
              (activity) =>
                  activity['status'] == 'Harvested' ||
                  activity['status'] == 'Failed',
            )
            .toList();

        setState(() {
          _harvestedActivities = completedActivities;
        });
      } else {
        _error = 'Format data tidak sesuai';
      }
    } catch (e) {
      _error = 'Gagal memuat data panen';
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
        title: const Text('Data Panen'),
        centerTitle: true,
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
              onPressed: _fetchHarvestedActivities,
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

    if (_harvestedActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.agriculture,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data hasil panen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data akan muncul setelah kegiatan tanam selesai (berhasil/gagal)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHarvestedActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _harvestedActivities.length,
        itemBuilder: (context, index) {
          final activity = _harvestedActivities[index];
          return _buildHarvestCard(activity);
        },
      ),
    );
  }

  Widget _buildHarvestCard(Map<String, dynamic> activity) {
    final seedData = activity['seedId'] as Map<String, dynamic>?;
    final landData = activity['landId'] as Map<String, dynamic>?;
    final seedName = seedData?['name'] ?? 'Tanaman tidak diketahui';
    final seedVariety = seedData?['variety']?.toString();
    final landName = landData?['name'] ?? 'Lahan tidak diketahui';
    final status = activity['status']?.toString() ?? '';

    final updatedAtStr = activity['updatedAt'] as String?;
    String completionDate = 'Tanggal tidak diketahui';

    if (updatedAtStr != null) {
      final date = DateTime.tryParse(updatedAtStr);
      if (date != null) {
        completionDate = _dateFormatter.format(date);
      }
    }

    final totalCost = (activity['totalCost'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (activity['totalRevenue'] as num?)?.toDouble() ?? 0;
    final profit = totalRevenue - totalCost;

    // Determine status display
    bool isFailed = status.toLowerCase() == 'failed';
    Color statusColor = isFailed ? Colors.red : Colors.green;
    IconData statusIcon = isFailed ? Icons.cancel : Icons.check_circle;
    String statusText = isFailed ? 'Gagal' : 'Dipanen';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPanenPage(
                kegiatanTanamId: activity['_id'],
                kegiatanTanamData: activity,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with harvest icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isFailed ? Icons.dangerous : Icons.agriculture,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seedVariety != null && seedVariety.isNotEmpty
                              ? '$seedName ($seedVariety)'
                              : seedName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D6A4F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                landName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Completion date section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _buildTimelineItem(
                  icon: isFailed ? Icons.dangerous : Icons.agriculture,
                  color: statusColor,
                  title: isFailed ? 'Tanggal Gagal' : 'Tanggal Panen',
                  date: completionDate,
                  isFirst: true,
                ),
              ),

              const SizedBox(height: 16),

              // Financial summary (only show if not failed or if there are costs)
              if (!isFailed || totalCost > 0) ...[
                Row(
                  children: [
                    _buildFinancialChip(
                      icon: Icons.arrow_downward,
                      color: Colors.red,
                      label: 'Biaya',
                      value: _currencyFormatter.format(totalCost),
                    ),
                    if (!isFailed) ...[
                      const SizedBox(width: 8),
                      _buildFinancialChip(
                        icon: Icons.arrow_upward,
                        color: Colors.green,
                        label: 'Pendapatan',
                        value: _currencyFormatter.format(totalRevenue),
                      ),
                      const SizedBox(width: 8),
                      _buildFinancialChip(
                        icon: profit >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: profit >= 0 ? Colors.blue : Colors.orange,
                        label: 'Profit',
                        value: _currencyFormatter.format(profit),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.red),
                              const SizedBox(height: 4),
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gagal Panen',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String date,
    required bool isFirst,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialChip({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
