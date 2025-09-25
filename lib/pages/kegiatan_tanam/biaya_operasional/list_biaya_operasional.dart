import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import 'add_biaya_operasional.dart';

class BiayaOperasionalListPage extends StatefulWidget {
  final String plantingActivityId;
  const BiayaOperasionalListPage({super.key, required this.plantingActivityId});

  @override
  State<BiayaOperasionalListPage> createState() =>
      _BiayaOperasionalListPageState();
}

class _BiayaOperasionalListPageState extends State<BiayaOperasionalListPage> {
  final ApiService _api = ApiService();
  final _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  bool _changed = false;

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
      final res = await _api.get(
        '/kegiatantanam/${widget.plantingActivityId}/biayaoperasional',
      );
      if (res.data is List) {
        setState(() => _items = (res.data as List));
      } else {
        _error = 'Format data tidak sesuai';
      }
    } catch (e) {
      _error = 'Gagal memuat data';
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
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
          title: const Text('Biaya Operasional'),
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => AddBiayaOperasionalPage(
                  plantingActivityId: widget.plantingActivityId,
                ),
              ),
            );
            if (result == true) {
              _fetch();
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
            ElevatedButton(onPressed: _fetch, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada biaya operasional.'));
    }
    final total = _items.fold<num>(
      0,
      (sum, e) => sum + ((e['amount'] as num?) ?? 0),
    );
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Biaya',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_currencyFormatter.format(total)),
                ],
              ),
            );
          }
          final item = _items[index - 1] as Map<String, dynamic>;
          final date = DateTime.tryParse(item['date']?.toString() ?? '');
          final costType = item['costType']?.toString() ?? '-';
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
          final notes = item['notes']?.toString();
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        costType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date != null ? _dateFormatter.format(date) : '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(notes),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
