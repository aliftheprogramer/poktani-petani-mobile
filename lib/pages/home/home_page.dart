import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../model/user.dart';
import '../profile/profile_page.dart'; // Import ProfilePage

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
  List<Map<String, dynamic>> semaiData = [];
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

  Future<void> _fetchAllData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Refresh user data as well
      _loadUserData();

      // Fetch data lahan dan semai saja
      final futures = await Future.wait([
        _apiService.get('/lahan'),
        _apiService.get('/semai'),
      ]);

      // Pastikan response berupa List, jika response API berupa Map, ambil dari key 'data'
      final lahanRaw = futures[0].data;
      final semaiRaw = futures[1].data;

      if (!mounted) return;

      setState(() {
        myLahans = lahanRaw is List
            ? List<Map<String, dynamic>>.from(lahanRaw)
            : (lahanRaw['data'] is List
                  ? List<Map<String, dynamic>>.from(lahanRaw['data'])
                  : []);
        semaiData = semaiRaw is List
            ? List<Map<String, dynamic>>.from(semaiRaw)
            : (semaiRaw['data'] is List
                  ? List<Map<String, dynamic>>.from(semaiRaw['data'])
                  : []);

        // Enhance lahan data dengan status dan productivity
        _enhanceLahanData();

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

  void _enhanceLahanData() {
    for (var lahan in myLahans) {
      // Tentukan status berdasarkan data semai
      String status = _determineStatus(lahan);
      lahan['status'] = status;

      // Hitung produktivitas (dummy calculation based on land area and semai data)
      double productivity = _calculateProductivity(lahan);
      lahan['productivity'] = productivity;
    }
  }

  String _determineStatus(Map<String, dynamic> lahan) {
    final semaiList = lahan['semai'] as List<dynamic>? ?? [];

    if (semaiList.isEmpty) {
      return 'Istirahat';
    }

    // Cek apakah ada semai yang masih aktif
    final now = DateTime.now();
    for (var semai in semaiList) {
      try {
        final endDate = DateTime.parse(semai['endDate']);
        if (endDate.isAfter(now)) {
          // Masih dalam periode semai
          return 'Masa Tanam';
        }
      } catch (e) {
        // Jika parsing gagal, asumsikan masa tanam
        return 'Masa Tanam';
      }
    }

    // Jika semai sudah selesai
    return 'Masa Tanam';
  }

  double _calculateProductivity(Map<String, dynamic> lahan) {
    // Hitung produktivitas berdasarkan berbagai faktor
    double baseProductivity = 75.0;

    // Faktor luas lahan
    final landArea = (lahan['landArea'] as num?)?.toDouble() ?? 0;
    if (landArea > 15000) {
      baseProductivity += 10.0;
    } else if (landArea > 5000) {
      baseProductivity += 5.0;
    }

    // Faktor pupuk
    final pupukList = lahan['pupuk'] as List<dynamic>? ?? [];
    if (pupukList.isNotEmpty) {
      baseProductivity += 5.0 * pupukList.length;
    }

    // Faktor pestisida
    final pestisidaList = lahan['pestisida'] as List<dynamic>? ?? [];
    if (pestisidaList.isNotEmpty) {
      baseProductivity += 3.0 * pestisidaList.length;
    }

    // Cap maksimal 95%
    return baseProductivity > 95.0 ? 95.0 : baseProductivity;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'masa tanam':
        return const Color(0xFF2E7D32);

      case 'istirahat':
        return const Color(0xFF424242);
      default:
        return const Color(0xFF424242);
    }
  }

  void _navigateToLahanDetail(Map<String, dynamic> lahan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasi ke detail lahan: ${lahan['name']}'),
        backgroundColor: const Color(0xFF2D6A4F),
      ),
    );
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
        .where((lahan) => lahan['status'] != 'Istirahat')
        .length;
    final avgProductivity = myLahans.isNotEmpty
        ? myLahans
                  .map((e) => e['productivity'] as double)
                  .reduce((a, b) => a + b) /
              myLahans.length
        : 0.0;

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
                  Icons.agriculture_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${avgProductivity.toStringAsFixed(1)}%',
                  'Produktivitas',
                  Icons.trending_up_rounded,
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigasi ke semua lahan'),
                    backgroundColor: const Color(0xFF2D6A4F),
                  ),
                );
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      lahan['status'] ?? 'Istirahat',
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    lahan['status'] ?? 'Istirahat',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                                      'Produktivitas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(lahan['productivity'] ?? 0.0).toStringAsFixed(1)}%',
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
