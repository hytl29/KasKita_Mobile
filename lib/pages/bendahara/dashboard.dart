import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardPage({super.key, required this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7CB9F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.userData['nama']} | ${widget.userData['role']}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
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
          const SizedBox(height: 16),
          _buildPaymentStatusCard(),
          const SizedBox(height: 16),
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
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

  Widget _buildPaymentStatusCard() {
    int sudah = _data!['sudah_bayar'];
    int total = _data!['total_murid'];
    double progress = total > 0 ? sudah / total : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sudah Bayar (Minggu Ini)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$sudah / $total Murid', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/img/group.png', width: 26, height: 26),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  backgroundColor: const Color(0xFFFFCBCB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA7F3D0)),
                ),
              ),
              const Icon(Icons.pie_chart_outline, size: 40, color: Colors.black12),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(const Color(0xFFFFCBCB), 'Belum Bayar ${total - sudah}'),
              const SizedBox(width: 20),
              _buildLegend(const Color(0xFFA7F3D0), 'Sudah Bayar $sudah'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    List aktivitas = _data!['aktivitas'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7CB9F3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Buat Transaksi', style: TextStyle(fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (aktivitas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("Belum ada aktivitas", style: TextStyle(color: Colors.grey))),
            )
          else
            ...aktivitas.map((a) => _buildActivityItem(a)).toList(),
          const SizedBox(height: 16),
          const Center(
            child: Text('Lihat Detail', style: TextStyle(color: Color(0xFF7CB9F3), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic a) {
    bool isMasuk = a['jenis'] == 'Masuk';
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
                Text(a['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${a['nama']} | ${a['tanggal']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (isMasuk && a['minggu_list'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFA7F3D0), borderRadius: BorderRadius.circular(4)),
                    child: Text('Week ${a['bulan']} ${a['tahun']} - Minggu ${a['minggu_list']}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  ),
              ],
            ),
          ),
          Text(
            '${isMasuk ? '+' : '-'} ${currencyFormatter.format(a['total_jumlah'])}',
            style: TextStyle(color: isMasuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
