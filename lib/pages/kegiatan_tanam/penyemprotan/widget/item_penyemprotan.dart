//item_pemupukan.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PenyemprotanListItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const PenyemprotanListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Asumsi ada field 'pesticideId' yang berisi Map dengan 'name'
    final pesticideData = item['pesticideId'] as Map<String, dynamic>?;
    final name = pesticideData?['name'] ?? 'Nama Pestisida Tidak Ada';

    final date = DateTime.tryParse(item['date'] ?? '');
    final formattedDate = date != null
        ? DateFormat('d MMMM yyyy', 'id_ID').format(date)
        : 'Tanggal tidak valid';

    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final unit = item['unit']?.toString() ?? '-';
    final pricePerUnit = (item['pricePerUnit'] as num?)?.toDouble() ?? 0;
    final totalCost = amount * pricePerUnit;

    final notes = item['notes']?.toString();

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.red.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          // TODO: Navigasi ke halaman detail penyemprotan jika ada
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.format_list_numbered_rtl,
                'Dosis',
                '$amount $unit',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.monetization_on_outlined,
                'Total Biaya',
                currencyFormatter.format(totalCost),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.notes_rounded, 'Catatan', notes),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
