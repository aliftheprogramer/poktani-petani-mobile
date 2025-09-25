//list_pestidida.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // <-- Sesuaikan path import ini

class PesticideSelectionPage extends StatefulWidget {
  const PesticideSelectionPage({super.key});

  @override
  State<PesticideSelectionPage> createState() => _PesticideSelectionPageState();
}

class _PesticideSelectionPageState extends State<PesticideSelectionPage> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<dynamic> _pesticides = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPesticides();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading) {
      _fetchPesticides();
    }
  }

  Future<void> _fetchPesticides({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 1;
        _pesticides = [];
        _hasMore = true;
      }
    });

    try {
      final res = await _api.get(
        '/pestisida?page=$_currentPage&limit=10&search=$_searchQuery',
      );
      final data = res.data['data'] as List;
      setState(() {
        _pesticides.addAll(data);
        _currentPage++;
        _hasMore = data.isNotEmpty;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchPesticides(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Pestisida'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama pestisida...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    if (_pesticides.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pesticides.isEmpty && !_isLoading) {
      return const Center(child: Text('Tidak ada data pestisida.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _pesticides.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _pesticides.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final pesticide = _pesticides[index];
        return ListTile(
          title: Text(pesticide['name'] ?? ''),
          subtitle: Text(
            '${pesticide['brand'] ?? ''} - ${pesticide['type'] ?? ''}',
          ),
          onTap: () {
            // Mengembalikan data pestisida yang dipilih ke halaman sebelumnya
            Navigator.pop(context, pesticide);
          },
        );
      },
    );
  }
}
