import 'package:flutter/material.dart';

class ListPanenPage extends StatefulWidget {
  final String landId;
  const ListPanenPage({super.key, required this.landId});

  @override
  State<ListPanenPage> createState() => _ListPanenPageState();
}

class _ListPanenPageState extends State<ListPanenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Panen Lahan'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Daftar hasil panen untuk lahan dengan ID: ${widget.landId}',
        ),
      ),
    );
  }
}
