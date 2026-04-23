import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DashboardSiswaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardSiswaPage({super.key, required this.userData});

  @override
  State<DashboardSiswaPage> createState() => _DashboardSiswaPageState();
}

class _DashboardSiswaPageState extends State<DashboardSiswaPage> {
  Map<String, dynamic>? _data;
  Map<String, List<int>> _statusKas = {};
  bool _isLoading = true;
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse("http://192.168.18.6/KasKitaAPI/dashboard.php")),
        http.post(
          Uri.parse("http://192.168.18.6/KasKitaAPI/get_status_siswa.php"),
          body: {'nisn': widget.userData['id'].toString(), 'tahun': '2026'},
        ),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        setState(() {
          _data = jsonDecode(results[0].body);
          var statusData = jsonDecode(results[1].body);
          _statusKas = Map<String, List<int>>.from(
            statusData['status'].map((key, value) => MapEntry(key, List<int>.from(value)))
          );
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF7CB9F3)));

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            _buildPersonalStatusGrid(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | Siswa', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Saldo Kas', _data?['saldo'], const Color(0xFF7CB9F3), 'wallet.png', true)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryCard('Total Masuk', _data?['pemasukan'], const Color(0xFFA7F3D0), 'up.png', false)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryCard('Total Keluar', _data?['pengeluaran'], const Color(0xFFFFCBCB), 'down.png', false)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, dynamic amount, Color color, String icon, bool isMain) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Image.asset('assets/img/$icon', width: 18, height: 18, color: isMain ? Colors.white : Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: isMain ? Colors.white70 : Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(currencyFormatter.format(amount ?? 0), style: TextStyle(color: isMain ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStatusGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Kas Anda (2026)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.grey.shade50),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF7CB9F3)),
                children: ['Bulan', '1', '2', '3', '4'].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                )).toList(),
              ),
              ..._months.map((m) {
                List<int> weeks = _statusKas[m] ?? [0, 0, 0, 0];
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text(m, style: const TextStyle(fontSize: 10))),
                    ...weeks.map((s) => Center(child: Icon(s == 1 ? Icons.check : Icons.close, color: s == 1 ? Colors.green : Colors.red.shade100, size: 14))),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    List aktivitas = _data?['aktivitas'] ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (aktivitas.isEmpty) const Center(child: Text("Belum ada aktivitas", style: TextStyle(color: Colors.grey)))
          else ...aktivitas.take(5).map((a) => _buildActivityItem(a)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic a) {
    bool isMasuk = a['jenis'].toString().toLowerCase() == 'masuk';
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isMasuk ? Colors.green : Colors.red).withOpacity(0.1),
            child: Image.asset('assets/img/${isMasuk ? "up.png" : "down.png"}', width: 16, height: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMasuk ? 'Pembayaran Kas' : (a['judul'] ?? a['keterangan']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${a['nama']} | ${a['tanggal']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (isMasuk && a['minggu_list'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFA7F3D0), borderRadius: BorderRadius.circular(5)),
                    child: Text('Minggu ${a['minggu_list']}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Text('${isMasuk ? "+" : "-"} ${currencyFormatter.format(a['total_jumlah'] ?? a['jumlah'] ?? 0)}', style: TextStyle(color: isMasuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
