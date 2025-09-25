import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class MulaiPemanenanPage extends StatefulWidget {
  final String kegiatanTanamId;
  final Map<String, dynamic>? kegiatanTanamData;

  const MulaiPemanenanPage({
    super.key,
    required this.kegiatanTanamId,
    this.kegiatanTanamData,
  });

  @override
  State<MulaiPemanenanPage> createState() => _MulaiPemanenanPageState();
}

class _MulaiPemanenanPageState extends State<MulaiPemanenanPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Form controllers
  final _amountController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _harvestCostController = TextEditingController();
  final _totalRevenueController = TextEditingController();

  // Form values
  DateTime _harvestDate = DateTime.now();
  String _saleType = 'Per Satuan';
  String _quality = 'A';
  final String _unit = 'kg'; // Fixed to kg as requested

  bool _isLoading = false;

  final _dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _calculateTotalRevenue();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sellingPriceController.dispose();
    _harvestCostController.dispose();
    _totalRevenueController.dispose();
    super.dispose();
  }

  void _calculateTotalRevenue() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final harvestCost = double.tryParse(_harvestCostController.text) ?? 0;
    // Total Pendapatan = (Harga Jual per kg x Jumlah Panen) - Biaya Panen
    final totalRevenue = (amount * sellingPrice) - harvestCost;
    _totalRevenueController.text = totalRevenue.round().toString();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF2D6A4F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'harvestDate': _harvestDate.toIso8601String(),
        'saleType': _saleType,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'unit': _unit,
        'quality': _quality,
        'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0,
        'harvestCost': double.tryParse(_harvestCostController.text) ?? 0,
        'totalRevenue': double.tryParse(_totalRevenueController.text) ?? 0,
      };

      await _api.post(
        '/kegiatantanam/${widget.kegiatanTanamId}/panen',
        data: requestBody,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panen berhasil dicatat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat panen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Mulai Pemanenan'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHarvestDateCard(),
                    const SizedBox(height: 16),
                    _buildSaleTypeCard(),
                    const SizedBox(height: 16),
                    _buildAmountCard(),
                    const SizedBox(height: 16),
                    _buildQualityCard(),
                    const SizedBox(height: 16),
                    _buildPriceCard(),
                    const SizedBox(height: 16),
                    _buildCostCard(),
                    const SizedBox(height: 16),
                    _buildTotalRevenueCard(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final landData =
        widget.kegiatanTanamData?['landId'] as Map<String, dynamic>?;
    final seedData =
        widget.kegiatanTanamData?['seedId'] as Map<String, dynamic>?;
    final landName = landData?['name'] ?? 'Lahan tidak diketahui';
    final seedName = seedData?['name'] ?? 'Tanaman tidak diketahui';

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A4F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tanaman: $seedName',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Waktu Panen Tiba!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestDateCard() {
    return _buildCard(
      title: 'Tanggal Panen',
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
      child: GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dateFormatter.format(_harvestDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleTypeCard() {
    return _buildCard(
      title: 'Jenis Penjualan',
      icon: Icons.sell,
      iconColor: Colors.orange,
      child: DropdownButtonFormField<String>(
        value: _saleType,
        decoration: _buildInputDecoration('Pilih jenis penjualan'),
        items: ['Per Satuan', 'Borongan'].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _saleType = newValue!;
          });
        },
        validator: (value) => value == null ? 'Pilih jenis penjualan' : null,
      ),
    );
  }

  Widget _buildAmountCard() {
    return _buildCard(
      title: 'Jumlah Panen',
      icon: Icons.scale,
      iconColor: Colors.green,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _amountController,
              decoration: _buildInputDecoration('Masukkan jumlah'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah panen';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
              onChanged: (value) {
                _calculateTotalRevenue();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: _unit,
              decoration: _buildInputDecoration('Unit'),
              enabled: false, // Disabled as requested
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard() {
    return _buildCard(
      title: 'Kualitas Panen',
      icon: Icons.stars,
      iconColor: Colors.purple,
      child: DropdownButtonFormField<String>(
        value: _quality,
        decoration: _buildInputDecoration('Pilih kualitas'),
        items: ['A', 'B', 'C'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: value == 'A'
                        ? Colors.green
                        : value == 'B'
                        ? Colors.orange
                        : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Kualitas $value'),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _quality = newValue!;
          });
        },
        validator: (value) => value == null ? 'Pilih kualitas panen' : null,
      ),
    );
  }

  Widget _buildPriceCard() {
    return _buildCard(
      title: 'Harga Jual per $_unit',
      icon: Icons.attach_money,
      iconColor: Colors.green,
      child: TextFormField(
        controller: _sellingPriceController,
        decoration: _buildInputDecoration('Masukkan harga jual'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Masukkan harga jual';
          }
          if (double.tryParse(value) == null || double.parse(value) <= 0) {
            return 'Masukkan harga yang valid';
          }
          return null;
        },
        onChanged: (value) {
          _calculateTotalRevenue();
        },
      ),
    );
  }

  Widget _buildCostCard() {
    return _buildCard(
      title: 'Biaya Panen',
      icon: Icons.money_off,
      iconColor: Colors.red,
      child: TextFormField(
        controller: _harvestCostController,
        decoration: _buildInputDecoration('Masukkan biaya panen'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Masukkan biaya panen';
          }
          if (double.tryParse(value) == null || double.parse(value) < 0) {
            return 'Masukkan biaya yang valid';
          }
          return null;
        },
        onChanged: (value) {
          _calculateTotalRevenue();
        },
      ),
    );
  }

  Widget _buildTotalRevenueCard() {
    return _buildCard(
      title: 'Total Pendapatan',
      icon: Icons.account_balance_wallet,
      iconColor: Colors.blue,
      child: TextFormField(
        controller: _totalRevenueController,
        decoration: _buildInputDecoration(
          'Total pendapatan',
        ).copyWith(enabled: false, filled: true, fillColor: Colors.grey[100]),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D6A4F),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitHarvest,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.agriculture, size: 24),
        label: Text(
          _isLoading ? 'Menyimpan...' : 'Catat Panen',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2D6A4F)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
