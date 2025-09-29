//pages/lahan/lahan_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:niteni/pages/kegiatan_tanam/kegiatan_tanam_add_page.dart';
import 'package:niteni/pages/kegiatan_tanam/kegiatan_tanam_detail_page.dart';
import '../../services/api_service.dart';

import '../kegiatan_tanam/kegiatan_tanam_page.dart';
import 'lahan_add_page.dart';

import '../../theme/app_theme.dart';

class LahanDetailPage extends StatefulWidget {
  final String id;
  const LahanDetailPage({super.key, required this.id});

  @override
  State<LahanDetailPage> createState() => _LahanDetailPageState();
}

class _LahanDetailPageState extends State<LahanDetailPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  List<dynamic> _kegiatanTanam = [];
  bool _deleting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetch();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch lahan detail
      final resLahan = await _api.get('/lahan/${widget.id}');
      final bodyLahan = resLahan.data;
      if (bodyLahan is Map<String, dynamic>) {
        _data = bodyLahan;
        _animationController.forward();
      } else {
        _data = null;
      }

      // Fetch kegiatan tanam (ambil lebih banyak untuk mendeteksi >3 non-harvested)
      final resKegiatan = await _api.get(
        '/kegiatantanam?landId=${widget.id}&limit=20',
      );
      final bodyKegiatan = resKegiatan.data;
      if (bodyKegiatan is Map<String, dynamic> &&
          bodyKegiatan['data'] is List) {
        final List data = bodyKegiatan['data'] as List;
        // Filter: hanya tampilkan yang statusnya 'Active'
        _kegiatanTanam = data
            .where(
              (item) =>
                  ((item as Map<String, dynamic>)['status'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  'active',
            )
            .toList();
      } else {
        _kegiatanTanam = [];
      }
    } catch (e) {
      _error = 'Gagal memuat detail lahan';
      _data = null;
      _kegiatanTanam = [];
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Hapus',
              style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus lahan ini? Semua data terkait akan hilang permanen.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        backgroundColor: kBackgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      final res = await _api.delete('/lahan/${widget.id}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Lahan berhasil dihapus',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Gagal menghapus lahan');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan saat menghapus');
    } finally {
      if (!mounted) return;
      setState(() => _deleting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _loading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _data == null
          ? _buildEmptyState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 20),
                          _buildKegiatanTanamSection(),
                          const SizedBox(height: 20),
                          _buildPanenSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _data!['name'] ?? 'Detail Lahan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: _data == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LahanAddPage(initialData: _data, editId: widget.id),
                      ),
                    );
                    _fetch();
                  },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, size: 20),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: _deleting ? null : _confirmAndDelete,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _deleting
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.landscape_rounded,
                  color: kPrimaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _data!['name'] ?? '-',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Aktif',
                        style: TextStyle(
                          color: Colors.green,
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
          const SizedBox(height: 20),
          _buildInfoItem(
            Icons.terrain_rounded,
            'Jenis Tanah',
            _data!['soilType'] ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.location_on_rounded,
            'Dusun',
            _data!['hamlet'] ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.home_work_rounded,
            'Desa',
            _data!['village'] ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.business_rounded,
            'Kecamatan',
            _data!['district'] ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.landscape_rounded,
            'Lahan',
            _data!['landArea'].toString(),
          ),
          const SizedBox(height: 12),
          if (_data!['latitude'] != null && _data!['longitude'] != null)
            _buildInfoItem(
              Icons.my_location,
              'Koordinat',
              'Lat: ${(_data!['latitude'] as num).toStringAsFixed(6)}, Lng: ${(_data!['longitude'] as num).toStringAsFixed(6)}',
            ),

          // Section: Preview Peta OSM
          const SizedBox(height: 16),
          Text(
            'Lokasi Lahan',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final latRaw = _data?['latitude'];
            final lngRaw = _data?['longitude'];
            LatLng? pos;
            if (latRaw is num && lngRaw is num) {
              pos = LatLng(latRaw.toDouble(), lngRaw.toDouble());
            }
            if (pos == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lokasi belum ditetapkan',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMapPreviewDetail(pos),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openInOSM(pos!),
                      icon: const Icon(Icons.public),
                      label: const Text('Buka di OpenStreetMap'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyCoords(pos!),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Salin Koordinat'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openFullMap(pos!),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Lihat Peta Penuh'),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildKegiatanTanamSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.grain_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kegiatan Tanam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KegiatanTanamAddPage(landId: widget.id),
                    ),
                  );
                  if (result == true) {
                    _fetch();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_kegiatanTanam.isEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tambah Baru'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KegiatanTanamAddPage(landId: widget.id),
                    ),
                  );
                  if (result == true) {
                    _fetch();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            )
          else ...[
            // Tampilkan maksimal 3 item kegiatan tanam
            ..._kegiatanTanam.take(3).map((item) {
              final map = (item as Map<String, dynamic>);
              final seed = map['seedId'] as Map<String, dynamic>?;
              final seedName = seed?['name']?.toString() ?? 'Benih';
              final seedVariety = seed?['variety']?.toString();
              final status = map['status']?.toString() ?? '-';
              final plantingDateStr = map['plantingDate']?.toString();
              final dateLabel =
                  plantingDateStr != null && plantingDateStr.length >= 10
                  ? plantingDateStr.substring(0, 10)
                  : '-';

              Color chipBg;
              Color chipFg;
              switch (status.toLowerCase()) {
                case 'active':
                  chipBg = Colors.green.shade100;
                  chipFg = Colors.green.shade800;
                  break;
                case 'harvested':
                  chipBg = Colors.teal.shade100;
                  chipFg = Colors.teal.shade800;
                  break;
                case 'pending':
                  chipBg = Colors.amber.shade100;
                  chipFg = Colors.amber.shade800;
                  break;
                case 'failed':
                  chipBg = Colors.red.shade100;
                  chipFg = Colors.red.shade800;
                  break;
                default:
                  chipBg = Colors.grey.shade200;
                  chipFg = Colors.grey.shade800;
              }

              final String? kegiatanId =
                  map['_id']?.toString() ?? map['id']?.toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: kegiatanId == null
                      ? null
                      : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  KegiatanTanamDetailPage(id: kegiatanId),
                            ),
                          );
                          if (result == true) {
                            _fetch();
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (seedVariety != null && seedVariety.isNotEmpty)
                                    ? '$seedName ($seedVariety)'
                                    : seedName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ditanam: $dateLabel',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: chipFg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_kegiatanTanam.length > 3)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KegiatanTanamPage(landId: widget.id),
                      ),
                    );
                    if (result == true) {
                      _fetch();
                    }
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: const Text('Lihat Semua Kegiatan Tanam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanenSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat detail lahan...',
                  style: TextStyle(
                    color: kTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetch,
              style: primaryButtonStyle(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Data Tidak Ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lahan yang Anda cari tidak ditemukan',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: primaryButtonStyle(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Lokasi & Peta Helpers =====
  Widget _buildMapPreviewDetail(LatLng pos) {
    final mapController = MapController();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pos,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.niteni',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pos,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          '© OpenStreetMap contributors',
                          onTap: () => _openInOSM(pos),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                children: [
                  _roundIconButton(
                    icon: Icons.add,
                    onTap: () {
                      final z = mapController.camera.zoom + 1;
                      mapController.move(pos, z);
                    },
                  ),
                  const SizedBox(height: 8),
                  _roundIconButton(
                    icon: Icons.remove,
                    onTap: () {
                      final z = mapController.camera.zoom - 1;
                      mapController.move(pos, z);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: Colors.grey.shade800),
        ),
      ),
    );
  }

  Future<void> _openInOSM(LatLng pos) async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}#map=17/${pos.latitude}/${pos.longitude}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka OpenStreetMap')),
      );
    }
  }

  Future<void> _copyCoords(LatLng pos) async {
    final text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Koordinat disalin: $text')),
    );
  }

  void _openFullMap(LatLng pos) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LahanFullMapPage(
          pos: pos,
          title: (_data?['name']?.toString() ?? 'Lokasi Lahan'),
        ),
      ),
    );
  }
}

class _LahanFullMapPage extends StatefulWidget {
  final LatLng pos;
  final String title;
  const _LahanFullMapPage({required this.pos, required this.title});

  @override
  State<_LahanFullMapPage> createState() => _LahanFullMapPageState();
}

class _LahanFullMapPageState extends State<_LahanFullMapPage> {
  final MapController _controller = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.pos,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.niteni',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.pos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () => _openInOSM(widget.pos),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _roundIconButton(
                  icon: Icons.add,
                  onTap: () {
                    final z = _controller.camera.zoom + 1;
                    _controller.move(widget.pos, z);
                  },
                ),
                const SizedBox(height: 8),
                _roundIconButton(
                  icon: Icons.remove,
                  onTap: () {
                    final z = _controller.camera.zoom - 1;
                    _controller.move(widget.pos, z);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInOSM(widget.pos),
        icon: const Icon(Icons.public),
        label: const Text('Buka di OSM'),
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: Colors.grey.shade800),
        ),
      ),
    );
  }

  Future<void> _openInOSM(LatLng pos) async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}#map=17/${pos.latitude}/${pos.longitude}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
