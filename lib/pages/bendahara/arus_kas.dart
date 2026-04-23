import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ArusKasPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ArusKasPage({super.key, required this.userData});

  @override
  State<ArusKasPage> createState() => _ArusKasPageState();
}

class _ArusKasPageState extends State<ArusKasPage> {
  bool _isLoading = true;
  List<dynamic> _transaksiList = [];
  Map<String, dynamic> _summary = {
    'saldo': 0,
    'pemasukan_filter': 0,
    'pengeluaran_filter': 0,
    'total_transaksi': 0,
  };

  String _selectedType = 'Semua Transaksi';
  String _selectedYear = DateFormat('yyyy').format(DateTime.now());
  String _selectedMonth = '';

  final List<String> _types = ['Semua Transaksi', 'Pemasukan', 'Pengeluaran'];
  final List<String> _years = ['2025', '2026', '2027'];
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[DateTime.now().month - 1];
    if (!_years.contains(_selectedYear)) {
      _selectedYear = _years.first;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/arus_kas.php"),
        body: {
          'type': _selectedType,
          'tahun': _selectedYear,
          'bulan': _selectedMonth,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _transaksiList = data['transaksi'];
          _summary = data['summary'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error arus kas: $e");
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
            _buildSaldoCard(),
            const SizedBox(height: 16),
            _buildIncomeExpenseRow(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arus Kas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | ${widget.userData['role']}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF7CB9F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Image.asset('assets/img/wallet.png', color: Colors.white, width: 24, height: 24),
          ),
          const SizedBox(height: 16),
          const Text('Total Saldo Kas', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(_summary['saldo']), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Saldo Terbaru', style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow() {
    return Row(
      children: [
        Expanded(child: _buildMiniStatCard('Total Pemasukan', _summary['pemasukan_filter'], const Color(0xFFA7F3D0), 'up.png')),
        const SizedBox(width: 16),
        Expanded(child: _buildMiniStatCard('Total Pengeluaran', _summary['pengeluaran_filter'], const Color(0xFFFFCBCB), 'down.png')),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, dynamic amount, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
            child: Image.asset('assets/img/$icon', width: 16, height: 16),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
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
          _buildDropdown(_selectedType, _types, (val) => setState(() { _selectedType = val!; _fetchData(); })),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown(_selectedYear, _years, (val) => setState(() { _selectedYear = val!; _fetchData(); }))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown(_selectedMonth, _months, (val) => setState(() { _selectedMonth = val!; _fetchData(); }))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    if (!items.contains(value)) {
      value = items.first;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Arus Kas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_summary['total_transaksi']} Transaksi', style: const TextStyle(color: Color(0xFF7CB9F3), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_transaksiList.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada transaksi", style: TextStyle(color: Colors.grey))))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transaksiList.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(_transaksiList[index], index == _transaksiList.length - 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic item, bool isLast) {
    bool isMasuk = item['jenis'].toString().toLowerCase() == 'masuk';
    var rawAmount = item['jumlah'] ?? 0;
    num amount = num.tryParse(rawAmount.toString()) ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMasuk ? const Color(0xFFA7F3D0).withOpacity(0.3) : const Color(0xFFFFCBCB).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(isMasuk ? 'assets/img/up.png' : 'assets/img/down.png', width: 20, height: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade100),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(isMasuk ? 'Pembayaran Kas' : (item['keterangan'] ?? 'Pengeluaran'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Text(
                      '${isMasuk ? "+" : "-"} ${currencyFormatter.format(amount)}',
                      style: TextStyle(color: isMasuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(item['nama'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(item['tanggal'] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (isMasuk && item['minggu_list'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFA7F3D0), borderRadius: BorderRadius.circular(6)),
                    child: Text('Week ${item['bulan']} ${item['tahun']} - Minggu ${item['minggu_list']}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
