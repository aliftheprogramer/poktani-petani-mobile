import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// If you need a typed result later, you can add it back. For now we return a Map.

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  final TextEditingController _searchCtrl = TextEditingController();
  final Dio _dio = Dio();
  List<_SearchItem> _searchResults = [];
  bool _loadingSearch = false;
  Timer? _debounce;
  bool _reverseLoading = false;
  String? _addressPreview;
  bool _mapReady = false;
  double _initialZoom = 13;

  static const _defaultCenter = LatLng(-7.797068, 110.370529); // Yogyakarta

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _moveTo(LatLng target) {
    if (!_mapReady) return;
    final z = _mapController.camera.zoom;
    _mapController.move(target, z);
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng latlng) async {
    setState(() => _selectedLatLng = latlng);
    await _reverseGeocode(latlng);
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    setState(() {
      _reverseLoading = true;
      _addressPreview = null;
    });
    try {
      final resp = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latlng.latitude,
          'lon': latlng.longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
          'zoom': 14,
        },
        options: Options(headers: {
          'User-Agent': 'poktani-petani-mobile/1.0 (contact: example@example.com)'
        }),
      );
      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      final address = data['address'] ?? {};
      final hamlet = address['hamlet'] ?? address['neighbourhood'] ?? address['suburb'];
      final village = address['village'] ?? address['town'] ?? address['city_district'];
      final district = address['county'] ?? address['state_district'] ?? address['municipality'];
      setState(() {
        _addressPreview = data['display_name'];
      });

      // Show bottom sheet with confirm
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _ConfirmSheet(
          address: _addressPreview ?? 'Lokasi terpilih',
          onConfirm: () {
            Navigator.pop(context); // close sheet
            Navigator.pop(context, {
              'latitude': latlng.latitude,
              'longitude': latlng.longitude,
              'hamlet': hamlet?.toString(),
              'village': village?.toString(),
              'district': district?.toString(),
            });
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan alamat: $e')),
      );
    } finally {
      if (mounted) setState(() => _reverseLoading = false);
    }
  }

  Future<void> _searchPlaces(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _loadingSearch = true);
    try {
      final resp = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'addressdetails': 1,
          'limit': 10,
          'countrycodes': 'id',
        },
        options: Options(headers: {
          'User-Agent': 'poktani-petani-mobile/1.0 (contact: example@example.com)'
        }),
      );

      final List list = resp.data is String ? jsonDecode(resp.data) : resp.data;
      setState(() {
        _searchResults = list
            .map((e) => _SearchItem(
                  title: e['display_name'],
                  lat: double.tryParse(e['lat']?.toString() ?? ''),
                  lon: double.tryParse(e['lon']?.toString() ?? ''),
                ))
            .where((e) => e.lat != null && e.lon != null)
            .cast<_SearchItem>()
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencari lokasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingSearch = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLatLng ?? _defaultCenter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari lokasi, desa, kecamatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loadingSearch
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          )),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.separated(
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = _searchResults[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      final latlng = LatLng(item.lat!, item.lon!);
                      setState(() {
                        _selectedLatLng = latlng;
                        _searchResults = [];
                        _searchCtrl.text = '';
                      });
                      _moveTo(latlng);
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _initialZoom,
                    onMapReady: () {
                      setState(() => _mapReady = true);
                      // If we already have a selected location before map is ready, ensure view is there
                      if (_selectedLatLng != null) {
                        _mapController.move(_selectedLatLng!, _initialZoom);
                      }
                    },
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'niteni.poktani_petani_mobile',
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_reverseLoading)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Mengambil alamat...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedLatLng == null
                          ? null
                          : () => _reverseGeocode(_selectedLatLng!),
                      icon: const Icon(Icons.check),
                      label: const Text('Gunakan Lokasi Ini'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String address;
  final VoidCallback onConfirm;
  const _ConfirmSheet({required this.address, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi Lokasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(address),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Pakai'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SearchItem {
  final String title;
  final double? lat;
  final double? lon;
  _SearchItem({required this.title, this.lat, this.lon});
}
