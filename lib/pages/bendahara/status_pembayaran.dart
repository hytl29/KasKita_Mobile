import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class StatusPembayaranPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const StatusPembayaranPage({super.key, required this.userData});

  @override
  State<StatusPembayaranPage> createState() => _StatusPembayaranPageState();
}

class _StatusPembayaranPageState extends State<StatusPembayaranPage> {
  bool _isLoading = true;
  List<dynamic> _muridList = [];
  Map<String, dynamic> _summary = {
    'sudah_bayar': 0,
    'belum_bayar': 0,
    'total_terkumpul': 0,
    'total_murid': 0,
  };

  String _selectedYear = DateFormat('yyyy').format(DateTime.now());
  String _selectedMonth = '';
  String _selectedWeek = '';
  String _selectedSort = 'Sort By Abjad';

  final List<String> _years = ['2025', '2026', '2027'];
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  final List<String> _weeks = ['1', '2', '3', '4'];
  final List<String> _sortOptions = ['Sort By Abjad', 'Status: Sudah Bayar', 'Status: Belum Bayar'];

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[DateTime.now().month - 1];
    _selectedWeek = ((DateTime.now().day / 7).ceil()).clamp(1, 4).toString();
    
    if (!_years.contains(_selectedYear)) {
      _selectedYear = _years.first;
    }
    
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/status_pembayaran.php"),
        body: {
          'tahun': _selectedYear,
          'bulan': _selectedMonth,
          'minggu': _selectedWeek,
          'sort': _selectedSort,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _muridList = data['murid'];
          _summary = data['summary'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error status: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status Pembayaran', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | ${widget.userData['role']}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Sudah Bayar (Minggu Ini)', '${_summary['sudah_bayar']}', 'dari ${_summary['total_murid']} Murid', const Color(0xFFA7F3D0), Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Belum Bayar (Minggu Ini)', '${_summary['belum_bayar']}', 'dari ${_summary['total_murid']} Murid', const Color(0xFFFFCBCB), Icons.cancel_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Total Terkumpul', currencyFormatter.format(_summary['total_terkumpul']), '', const Color(0xFF7CB9F3), Icons.payments_outlined, isBlue: true)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub, Color color, IconData icon, {bool isBlue = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isBlue ? Colors.white70 : Colors.black45, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isBlue ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isBlue ? Colors.white : Colors.black87)),
          if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 9, color: isBlue ? Colors.white60 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown(_selectedYear, _years, (val) => setState(() { _selectedYear = val!; _fetchData(); }))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown(_selectedMonth, _months, (val) => setState(() { _selectedMonth = val!; _fetchData(); }))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown('Minggu: $_selectedWeek', _weeks, (val) => setState(() { _selectedWeek = val!; _fetchData(); }), isWeek: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown(_selectedSort, _sortOptions, (val) => setState(() { _selectedSort = val!; _fetchData(); }))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, {bool isWeek = false}) {
    String currentValue = isWeek ? value.split(': ').last : value;
    
    if (!items.contains(currentValue)) {
      currentValue = items.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(isWeek ? 'Minggu: $e' : e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF7CB9F3),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Nama Murid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 80, child: Text('NISN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 70, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _muridList.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final m = _muridList[index];
                bool isLunas = m['status_bayar'] == 'Sudah Bayar';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                      Expanded(child: Text(m['nama'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                      SizedBox(width: 80, child: Text(m['nisn'], style: const TextStyle(fontSize: 11, color: Colors.black45))),
                      SizedBox(
                        width: 70,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: isLunas ? const Color(0xFFA7F3D0).withOpacity(0.3) : const Color(0xFFFFCBCB).withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                          child: Text(isLunas ? 'Sudah\nBayar' : 'Belum\nBayar', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isLunas ? Colors.green : Colors.red)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
