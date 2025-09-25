// lib/pages/semaian/semaian_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import package intl
import 'package:niteni/pages/semaian/widget/siap_pindah_popup.dart';
import '../../services/api_service.dart';
import 'semaian_add_page.dart';

class SemaianDetailPage extends StatefulWidget {
  final String id;
  const SemaianDetailPage({super.key, required this.id});

  @override
  State<SemaianDetailPage> createState() => _SemaianDetailPageState();
}

class _SemaianDetailPageState extends State<SemaianDetailPage> {
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  bool _deleting = false;

  // Formatter untuk tanggal dan mata uang
  final _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semai'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      final res = await _api.delete('/semai/${widget.id}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menghapus semai')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus (${res.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menghapus')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _deleting = false);
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/semai/${widget.id}');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        _data = body;
      } else {
        _data = null;
      }
    } catch (e) {
      _error = 'Gagal memuat detail semai';
      _data = null;
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  double _calculateProgress(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0.0;

    final now = DateTime.now();
    final totalDuration = end.difference(start).inSeconds;

    if (totalDuration <= 0) {
      return now.isAfter(end) ? 1.0 : 0.0;
    }

    final elapsedDuration = now.difference(start).inSeconds;

    if (elapsedDuration < 0) return 0.0;
    if (elapsedDuration > totalDuration) return 1.0;

    return elapsedDuration / totalDuration;
  }

  String _getProgressText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';

    final now = DateTime.now();

    if (now.isBefore(start)) {
      final daysUntilStart = start.difference(now).inDays + 1;
      return 'Dimulai dalam $daysUntilStart hari';
    }

    if (now.isAfter(end)) {
      return 'Periode semai telah selesai';
    }

    final totalDays = end.difference(start).inDays + 1;
    final elapsedDays = now.difference(start).inDays + 1;

    return 'Hari ke-$elapsedDays dari $totalDays hari';
  }

  Future<void> _showSiapPindahPopup() async {
    if (_data == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiapPindahPopup(semaiId: widget.id),
    );

    if (result == true) {
      await _fetch(); // Refresh data if submission was successful
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
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail Semai'), centerTitle: true),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? RefreshIndicator(
                  onRefresh: _fetch,
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
              : _data == null
              ? RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Data semai tidak ditemukan.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 0,
                        color: const Color(0xFFEEEEEE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.black.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _deleting
                                      ? null
                                      : () async {
                                          if (_data == null) return;

                                          // Menyiapkan data untuk dikirim ke halaman Edit
                                          final seedIdData =
                                              _data!['seedId']
                                                  as Map<String, dynamic>? ??
                                              {};
                                          final totalCost =
                                              (_data!['cost'] as num?)
                                                  ?.toDouble() ??
                                              0.0;
                                          final amount =
                                              (_data!['seedAmount'] as num?)
                                                  ?.toDouble() ??
                                              1.0;
                                          final pricePerUnit = (amount > 0)
                                              ? totalCost / amount
                                              : 0.0;

                                          final initialDataForEdit = {
                                            ..._data!,
                                            'seedType': {
                                              '_id': seedIdData['_id'],
                                              'name': seedIdData['name'],
                                              'variety': seedIdData['variety'],
                                              'price': pricePerUnit,
                                            },
                                          };

                                          final updated =
                                              await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SemaianAddPage(
                                                        initialData:
                                                            initialDataForEdit,
                                                        editId: widget.id,
                                                      ),
                                                ),
                                              );
                                          if (updated == true) {
                                            await _fetch();
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D6A4F),
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _deleting
                                      ? null
                                      : _confirmAndDelete,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.delete),
                                  label: Text(
                                    _deleting ? 'Menghapus...' : 'Hapus',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: const Color(0xFFEEEEEE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.black.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildDetail(_data!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: _buildReadyButton(),
      ),
    );
  }

  Widget? _buildReadyButton() {
    if (_data == null) return null;

    final status = _data!['status']?.toString();
    // Only show the button if the status is 'Persiapan'
    if (status != 'Persiapan') {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: FilledButton.icon(
        onPressed: _showSiapPindahPopup,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Siap Pindah'),
      ),
    );
  }

  // == WIDGET BUILDER UNTUK DETAIL TELAH DIPERBARUI ==
  List<Widget> _buildDetail(Map<String, dynamic> data) {
    final List<Widget> children = [];

    void addRow(String label, String? value, {IconData? icon}) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: const Color(0xFF2D6A4F)),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value ?? '-',
                  style: TextStyle(color: Colors.grey[800], fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Informasi Benih
    final seedData = data['seedId'] as Map<String, dynamic>?;
    final seedName = seedData?['name']?.toString();
    final seedVariety = seedData?['variety']?.toString();
    final seedFullName = [
      seedName,
      if (seedVariety != null) '($seedVariety)',
    ].join(' ');

    addRow('Benih', seedFullName, icon: Icons.grass);
    addRow(
      'Jumlah',
      '${data['seedAmount']} ${data['seedUnit']}',
      icon: Icons.scale,
    );
    addRow(
      'Lokasi',
      data['nurseryLocation']?.toString(),
      icon: Icons.location_on,
    );

    children.add(const Divider(height: 24));

    // Informasi Periode
    final startDate = _parseDate(data['startDate']?.toString());
    final endDate = _parseDate(data['estimatedReadyDate']?.toString());

    addRow(
      'Tanggal Mulai',
      startDate != null ? _dateFormatter.format(startDate) : '-',
      icon: Icons.play_arrow,
    );
    addRow(
      'Perkiraan Siap',
      endDate != null ? _dateFormatter.format(endDate) : '-',
      icon: Icons.stop,
    );
    addRow('Status', data['status']?.toString(), icon: Icons.label);

    // Progress Section
    if (startDate != null && endDate != null) {
      final progress = _calculateProgress(startDate, endDate);
      final progressText = _getProgressText(startDate, endDate);

      children.add(const SizedBox(height: 8));
      children.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.timeline, size: 20, color: Color(0xFF2D6A4F)),
                  SizedBox(width: 8),
                  Text(
                    'Progress Semai',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                progressText,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : const Color(0xFF2D6A4F),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}% selesai',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
      children.add(const Divider(height: 24));
    }

    // Informasi Biaya dan Hasil
    final cost = (data['cost'] as num?)?.toDouble();
    addRow(
      'Total Biaya',
      cost != null ? _currencyFormatter.format(cost) : '-',
      icon: Icons.monetization_on,
    );

    final yieldAmount = data['seedlingYield']?.toString() ?? '0';
    final yieldUnit = data['yieldUnit']?.toString() ?? 'batang';
    addRow('Hasil Bibit', '$yieldAmount $yieldUnit', icon: Icons.eco);

    children.add(const Divider(height: 24));

    addRow('Catatan', data['notes']?.toString(), icon: Icons.note);

    return children;
  }
}
