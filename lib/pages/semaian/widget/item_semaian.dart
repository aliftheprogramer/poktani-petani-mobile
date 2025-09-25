import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import paket intl untuk format tanggal

class ItemSemai extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  const ItemSemai({super.key, required this.data, this.onTap});

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // API mengembalikan format ISO 8601 (UTC), DateTime.parse bisa menanganinya
      return DateTime.parse(dateStr);
    } catch (e) {
      // Tambahkan fallback jika formatnya berbeda
      return null;
    }
  }

  // Helper untuk format tanggal agar lebih mudah dibaca
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    // Format menjadi: 28 Agu 2025
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  double _calculateProgress(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0.0;

    final now = DateTime.now();
    // Gunakan .toUtc() untuk memastikan perbandingan apel-ke-apel jika zona waktu berbeda
    final totalDuration = end.difference(start);

    // Jika tanggal mulai dan selesai sama, anggap progres 100% jika sudah hari H
    if (totalDuration.inSeconds <= 0) {
      return now.isAfter(start) ? 1.0 : 0.0;
    }

    final elapsedDuration = now.difference(start);

    if (elapsedDuration.isNegative) return 0.0; // Belum dimulai
    if (elapsedDuration > totalDuration) return 1.0; // Sudah selesai

    return elapsedDuration.inSeconds / totalDuration.inSeconds;
  }

  String _getProgressText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Informasi periode tidak lengkap';

    final now = DateTime.now();
    final totalDays = end.difference(start).inDays;
    final elapsedDays = now.difference(start).inDays;

    if (totalDays < 0) return 'Tanggal periode tidak valid';

    if (now.isBefore(start)) {
      final daysUntilStart = start.difference(now).inDays + 1;
      return 'Dimulai dalam $daysUntilStart hari';
    } else if (now.isAfter(end)) {
      return 'Selesai';
    } else {
      // Tambah 1 agar hitungan hari dimulai dari 1 bukan 0
      return 'Hari ke-${elapsedDays + 1} dari ${totalDays + 1} hari';
    }
  }

  @override
  Widget build(BuildContext context) {
    // UBAH: Menggunakan 'seedId' sesuai dengan respons JSON
    final seedInfo = data['seedId'] as Map<String, dynamic>?;
    final name = seedInfo?['name']?.toString() ?? 'Nama Benih Tidak Tersedia';
    final variety = seedInfo?['variety']?.toString() ?? '';

    final seedAmount = data['seedAmount']?.toString() ?? '-';
    final seedUnit = data['seedUnit']?.toString() ?? '';
    final notes = data['notes']?.toString() ?? '';

    // UBAH: Menggunakan 'estimatedReadyDate' untuk tanggal selesai
    final startStr = data['startDate']?.toString();
    final endStr = data['estimatedReadyDate']?.toString();

    final startDate = _parseDate(startStr);
    final endDate = _parseDate(endStr);

    // Format tanggal untuk ditampilkan
    final formattedStartDate = _formatDate(startDate);
    final formattedEndDate = _formatDate(endDate);

    final progress = _calculateProgress(startDate, endDate);
    final progressText = _getProgressText(startDate, endDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: const Color(0xFFEEEEEE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: InkWell(
        // Menggunakan InkWell untuk efek ripple saat di-tap
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D6A4F),
                ),
              ),
              const SizedBox(height: 8),
              if (variety.isNotEmpty)
                _buildInfoRow(Icons.grass, 'Varietas', variety, context),
              _buildInfoRow(
                Icons.scale,
                'Jumlah',
                '$seedAmount $seedUnit',
                context,
              ),
              if (startDate != null || endDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Periode',
                  '$formattedStartDate - $formattedEndDate',
                  context,
                ),

              // Progress bar section
              if (startDate != null && endDate != null) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Progress: ',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                        ),
                        Expanded(
                          child: Text(
                            progressText,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0
                              ? Colors.green
                              : progress >= 0.8
                              ? Colors.orange
                              : const Color(0xFF2D6A4F),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          progress >= 1.0
                              ? 'Selesai'
                              : progress <= 0 &&
                                    DateTime.now().isBefore(startDate)
                              ? 'Belum mulai'
                              : 'Berjalan',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: progress >= 1.0
                                    ? Colors.green
                                    : progress <= 0 &&
                                          DateTime.now().isBefore(startDate)
                                    ? Colors.grey[600]
                                    : const Color(0xFF2D6A4F),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              if (notes.isNotEmpty) ...[
                const Divider(height: 24, thickness: 0.5),
                _buildInfoRow(Icons.note, 'Catatan', notes, context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
