import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LaporanPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LaporanPage({super.key, required this.userData});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String _selectedRange = '6';
  String _selectedTampilan = 'ringkasan';

  final List<Map<String, String>> _ranges = [
    {'label': '1 Bulan Terakhir', 'value': '1'},
    {'label': '3 Bulan Terakhir', 'value': '3'},
    {'label': '6 Bulan Terakhir', 'value': '6'},
    {'label': '1 Tahun Terakhir', 'value': '12'},
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/laporan.php"),
        body: {'periode': _selectedRange, 'tampilan': _selectedTampilan},
      );

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error laporan: $e");
      setState(() => _isLoading = false);
    }
  }

  num _toNum(dynamic val) => num.tryParse(val.toString()) ?? 0;

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
            _buildFilters(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_data != null) ...[
              if (_selectedTampilan == 'ringkasan') ...[
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildMonthlyProgress(),
                const SizedBox(height: 24),
                _buildCategoryProgress(),
                const SizedBox(height: 24),
                _buildMonthlyDetailTable(),
              ] else ...[
                _buildIncomeDetailTable(),
                const SizedBox(height: 24),
                _buildExpenseDetailTable(),
              ],
              const SizedBox(height: 24),
            ] else
              const Center(child: Text("Gagal memuat data laporan")),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Laporan Kas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | ${widget.userData['role']}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTampilan,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'ringkasan', child: Text('Ringkasan', style: TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'detail', child: Text('Detail', style: TextStyle(fontSize: 14))),
                ],
                onChanged: (val) => setState(() { _selectedTampilan = val!; _fetchData(); }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRange,
                isExpanded: true,
                items: _ranges.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (val) => setState(() { _selectedRange = val!; _fetchData(); }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF7CB9F3), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Image.asset('assets/img/wallet.png', color: Colors.white, width: 24, height: 24),
                  ),
                  const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Saldo Bersih', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(currencyFormatter.format(_toNum(_data!['saldo_bersih'])), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniStatCard('Total Pemasukan', _toNum(_data!['total_pemasukan']), const Color(0xFFA7F3D0), 'up.png')),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniStatCard('Total Pengeluaran', _toNum(_data!['total_pengeluaran']), const Color(0xFFFFCBCB), 'down.png')),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, num amount, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
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

  Widget _buildMonthlyProgress() {
    List data = _data!['pemasukan_per_bulan'] ?? [];
    int totalMurid = _toNum(_data!['total_murid']).toInt();
    if (totalMurid == 0) totalMurid = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Persentase Pemasukan Per Bulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (data.isEmpty) const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
          ...data.map((item) {
            int muridBayar = _toNum(item['jumlah_murid_bayar']).toInt();
            double pct = (muridBayar / totalMurid).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['kategori']} ($muridBayar/$totalMurid Murid)', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(currencyFormatter.format(_toNum(item['total_uang'])), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 8, backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA7F3D0)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).toStringAsFixed(0)}% Siswa Bayar', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress() {
    List data = _data!['pengeluaran_per_kategori'] ?? [];
    num totalKeluar = _toNum(_data!['total_pengeluaran']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengeluaran Per Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (data.isEmpty) const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
          ...data.map((item) {
            num amount = _toNum(item['total']);
            double pct = totalKeluar > 0 ? (amount / totalKeluar).toDouble().clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['kategori'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(currencyFormatter.format(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 8, backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFCBCB)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetailTable() {
    List details = _data!['monthly_details'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Laporan Detail Bulanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Bulan')),
                DataColumn(label: Text('Pemasukan')),
                DataColumn(label: Text('Pengeluaran')),
                DataColumn(label: Text('Saldo')),
              ],
              rows: [
                ...details.map((d) {
                  num inAmt = _toNum(d['masuk']);
                  num outAmt = _toNum(d['keluar']);
                  return DataRow(cells: [
                    DataCell(Text(d['label'])),
                    DataCell(Text('+ ${currencyFormatter.format(inAmt)}', style: const TextStyle(color: Colors.green))),
                    DataCell(Text('- ${currencyFormatter.format(outAmt)}', style: const TextStyle(color: Colors.red))),
                    DataCell(Text(currencyFormatter.format(inAmt - outAmt))),
                  ]);
                }).toList(),
                DataRow(cells: [
                  const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(currencyFormatter.format(_toNum(_data!['total_pemasukan'])), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(currencyFormatter.format(_toNum(_data!['total_pengeluaran'])), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(currencyFormatter.format(_toNum(_data!['saldo_bersih'])), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeDetailTable() {
    List list = _data!['detail_pemasukan'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Pemasukan per Murid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 700),
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Tanggal Input', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nama Murid', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Untuk Bulan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Minggu', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: list.map<DataRow>((d) {
                  return DataRow(cells: [
                    DataCell(Text(d['tanggal'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(d['nama'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${d['bulan']} ${d['tahun']}', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFA7F3D0).withOpacity(0.4), borderRadius: BorderRadius.circular(15)),
                        child: Text('Minggu ${d['minggu_list']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                    ),
                    DataCell(Text('+ ${currencyFormatter.format(_toNum(d['total']))}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseDetailTable() {
    List list = _data!['detail_pengeluaran'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 600),
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Di-Input Oleh', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: list.map<DataRow>((d) {
                  return DataRow(cells: [
                    DataCell(Text(d['tanggal'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(d['keterangan'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(d['nama'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text('- ${currencyFormatter.format(_toNum(d['jumlah']))}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
