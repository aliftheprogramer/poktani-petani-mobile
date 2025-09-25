import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../model/user.dart';
import '../profile/profile_page.dart'; // Import ProfilePage
import '../lahan/lahan_detail_page.dart';
import '../lahan/lahan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Data states
  List<Map<String, dynamic>> myLahans = [];
  // Panen (harvest) counts per lahanId and active land tracking (based on kegiatan tanam status)
  Map<String, int> _harvestCounts = {};
  Set<String> _activeLandIds = {};
  User? _currentUser;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchAllData();
  }

  void _loadUserData() {
    setState(() {
      _currentUser = _storageService.getUserData();
    });
  }

  String _getDisplayName() {
    if (_currentUser?.fullName?.isNotEmpty == true) {
      // Get first name from full name (split by space and take first part)
      final names = _currentUser!.fullName!.split(' ');
      return names.first;
    }
    return 'Pengguna';
  }

  String _getUserInitial() {
    if (_currentUser?.fullName?.isNotEmpty == true) {
      return _currentUser!.fullName![0].toUpperCase();
    }
    return 'U';
  }

  String? _landIdOf(Map<String, dynamic> lahan) {
    final dynamic anyId = lahan['_id'] ?? lahan['id'];
    return anyId?.toString();
  }

  Future<void> _fetchAllData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Refresh user data as well
      _loadUserData();

      // Fetch lahan and kegiatan tanam to compute real panen counts and active lands
      final futures = await Future.wait([
        _apiService.get('/lahan'),
        _apiService.get('/kegiatantanam'),
      ]);

      // Pastikan response berupa List, jika response API berupa Map, ambil dari key 'data'
      final lahanRaw = futures[0].data;
      final kegiatanRaw = futures[1].data;

      if (!mounted) return;

      setState(() {
        myLahans = lahanRaw is List
            ? List<Map<String, dynamic>>.from(lahanRaw)
            : (lahanRaw['data'] is List
                  ? List<Map<String, dynamic>>.from(lahanRaw['data'])
                  : []);
        // Compute harvest counts and active land ids from kegiatan tanam
        final List<Map<String, dynamic>> kegiatanList = kegiatanRaw is List
            ? List<Map<String, dynamic>>.from(kegiatanRaw)
            : (kegiatanRaw is Map && kegiatanRaw['data'] is List
                  ? List<Map<String, dynamic>>.from(kegiatanRaw['data'])
                  : <Map<String, dynamic>>[]);

        _harvestCounts = {};
        _activeLandIds = {};
        for (final act in kegiatanList) {
          final status = (act['status']?.toString() ?? '').toLowerCase();
          final land = act['landId'];
          String? landId;
          if (land is String) {
            landId = land;
          } else if (land is Map) {
            final id = land['_id'] ?? land['id'];
            if (id != null) landId = id.toString();
          }
          if (landId == null || landId.isEmpty) continue;

          if (status == 'harvested') {
            _harvestCounts.update(landId, (v) => v + 1, ifAbsent: () => 1);
          } else if (status == 'active') {
            // Lahan dianggap aktif hanya jika memiliki kegiatan tanam dengan status 'active'
            _activeLandIds.add(landId);
          }
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Gagal memuat data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String _formatLandArea(dynamic landArea) {
    if (landArea == null) return '0 m²';
    final area = landArea.toDouble();
    if (area >= 10000) {
      return '${(area / 10000).toStringAsFixed(1)} ha';
    } else {
      return '${area.toInt()} m²';
    }
  }

  void _navigateToLahanDetail(Map<String, dynamic> lahan) async {
    final id = _landIdOf(lahan);
    if (id == null || id.isEmpty) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LahanDetailPage(id: id)),
    );
    if (mounted && result == true) {
      await _fetchAllData();
    }
  }

  // Method untuk navigasi ke halaman profile
  void _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    // Refresh user data when returning from profile page
    if (result != null || mounted) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFEEEEEE),
          title: Row(
            children: [
              GestureDetector(
                onTap: _navigateToProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2D6A4F),
                  child: Text(
                    _getUserInitial(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap:
                      _navigateToProfile, // Navigasi ke profile saat nama diklik
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        _getDisplayName(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Menghilangkan refresh button dan mengganti dengan profile button
              IconButton(
                onPressed: _navigateToProfile,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: const Color(0xFF2D6A4F),
                    size: 24,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: const Color(0xFF2D6A4F)),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat data pertanian...',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                      ),
                      child: Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchAllData,
                color: const Color(0xFF2D6A4F),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Summary
                        _buildQuickStats(),
                        const SizedBox(height: 24),

                        // Lahanku Section
                        _buildLahankuSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalLahan = myLahans.length;
    final activeLahan = myLahans
        .where((lahan) => _activeLandIds.contains(_landIdOf(lahan)))
        .length;
    final totalPanen = _harvestCounts.values.isEmpty
        ? 0
        : _harvestCounts.values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D6A4F),
            const Color(0xFF2D6A4F).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pertanian Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '$totalLahan',
                  'Total Lahan',
                  Icons.landscape_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '$activeLahan',
                  'Lahan Aktif',
                  Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '$totalPanen',
                  'Jumlah Panen',
                  Icons.agriculture,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLahankuSection() {
    if (myLahans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lahanku',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.landscape_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada lahan terdaftar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Tambahkan lahan pertama Anda',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lahanku',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LahanPage()),
                );
                if (mounted && result == true) {
                  await _fetchAllData();
                }
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  color: const Color(0xFF2D6A4F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 225,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myLahans.length,
            itemBuilder: (context, index) {
              final lahan = myLahans[index];
              return GestureDetector(
                onTap: () => _navigateToLahanDetail(lahan),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2D6A4F).withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header dengan gradient
                      Container(
                        width: double.infinity,
                        height: 78,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2D6A4F),
                              const Color(0xFF2D6A4F).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lahan['name'] ?? 'Lahan Tanpa Nama',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Builder(
                                  builder: (_) {
                                    final id = _landIdOf(lahan) ?? '';
                                    final isActive = _activeLandIds.contains(
                                      id,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF424242),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive ? 'Aktif' : 'Tidak Aktif',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${lahan['hamlet'] ?? '-'}, ${lahan['village'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Content area
                      Container(
                        height: 142,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Luas Lahan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatLandArea(lahan['landArea']),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D6A4F),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Jumlah Panen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_harvestCounts[_landIdOf(lahan)] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D6A4F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.eco_rounded,
                                    size: 16,
                                    color: const Color(0xFF2D6A4F),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tanah ${lahan['soilType'] ?? 'tidak diketahui'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
