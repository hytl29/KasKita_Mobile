import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DashboardKetuaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardKetuaPage({super.key, required this.userData});

  @override
  State<DashboardKetuaPage> createState() => _DashboardKetuaPageState();
}

class _DashboardKetuaPageState extends State<DashboardKetuaPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.18.6/KasKitaAPI/dashboard.php"));
      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7CB9F3)));
    }

    if (_data == null) {
      return const Center(child: Text("Gagal memuat data"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3)),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.userData['nama']} | Ketua Kelas',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildSaldoCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Pemasukan', _data!['pemasukan'], const Color(0xFFA7F3D0), 'up.png')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total Pengeluaran', _data!['pengeluaran'], const Color(0xFFFFCBCB), 'down.png')),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentActivityCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF7CB9F3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: Image.asset('assets/img/wallet.png', color: Colors.white, width: 26, height: 26),
          ),
          const SizedBox(height: 16),
          const Text('Saldo Kas', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(_data!['saldo']),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic amount, Color color, String iconName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
            child: Image.asset('assets/img/$iconName', width: 16, height: 16),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(amount),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    List aktivitas = _data!['aktivitas'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (aktivitas.isEmpty)
            const Center(child: Text("Belum ada aktivitas", style: TextStyle(color: Colors.grey)))
          else
            ...aktivitas.map((a) => _buildActivityItem(a)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic a) {
    bool isMasuk = a['jenis'].toString().toLowerCase() == 'masuk';
    var rawAmount = a['total_jumlah'] ?? a['jumlah'] ?? 0;
    num amount = num.tryParse(rawAmount.toString()) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMasuk ? const Color(0xFFA7F3D0).withOpacity(0.3) : const Color(0xFFFFCBCB).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Image.asset(isMasuk ? 'assets/img/up.png' : 'assets/img/down.png', width: 20, height: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMasuk ? 'Pembayaran Kas' : (a['judul'] ?? a['keterangan'] ?? 'Pengeluaran'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${a['nama']} | ${a['tanggal']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '${isMasuk ? '+' : '-'} ${currencyFormatter.format(amount)}',
            style: TextStyle(color: isMasuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
