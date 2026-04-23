import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BuatTransaksiPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BuatTransaksiPage({super.key, required this.userData});

  @override
  State<BuatTransaksiPage> createState() => _BuatTransaksiPageState();
}

class _BuatTransaksiPageState extends State<BuatTransaksiPage> {
  String _activeTab = 'pemasukan';
  String _activeSubTab = 'minggu';

  // Form Data Pemasukan
  List<dynamic> _muridList = [];
  String? _selectedNisn;
  final TextEditingController _tahunController = TextEditingController();
  final TextEditingController _bulanController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  // Form Data Pengeluaran
  final TextEditingController _tglKeluarController = TextEditingController();
  final TextEditingController _jmlKeluarController = TextEditingController();
  String? _selectedKategori;
  final List<String> _kategoriList = ['ATK', 'Kegiatan Sekolah', 'Perbaikan Fasilitas', 'Konsumsi', 'Lainnya'];

  // Status Data
  List<int> _mingguLunas = [];
  List<int> _mingguDipilih = [];
  Map<String, int> _mingguPerBulanData = {};
  List<String> _bulanDipilih = [];

  int _totalPemasukan = 0;
  int _totalPengeluaran = 0;
  int _jmlPemasukan = 0;
  int _jmlPengeluaran = 0;
  int _saldoBersih = 0;
  List<dynamic> _riwayatMasuk = [];
  List<dynamic> _riwayatKeluar = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final List<String> _daftarBulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchStats();
    await _fetchMurid();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.18.6/KasKitaAPI/dashboard.php"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalPemasukan = int.tryParse(data['pemasukan'].toString()) ?? 0;
          _totalPengeluaran = int.tryParse(data['pengeluaran'].toString()) ?? 0;
          _saldoBersih = int.tryParse(data['saldo'].toString()) ?? 0;
          
          List allAktivitas = data['aktivitas'] ?? [];
          _riwayatMasuk = allAktivitas.where((a) => a['jenis'].toString().toLowerCase() == 'masuk').toList();
          _riwayatKeluar = allAktivitas.where((a) => a['jenis'].toString().toLowerCase() == 'keluar').toList();
          
          _jmlPemasukan = _riwayatMasuk.length;
          _jmlPengeluaran = _riwayatKeluar.length;
        });
      }
    } catch (e) {
      debugPrint("Error stats: $e");
    }
  }

  Future<void> _fetchMurid() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.18.6/KasKitaAPI/get_murid.php"));
      if (response.statusCode == 200) {
        setState(() {
          _muridList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error murid: $e");
    }
  }

  Future<void> _onMuridChanged(String? nisn) async {
    setState(() {
      _selectedNisn = nisn;
      _tahunController.clear();
      _bulanController.clear();
      _mingguLunas = [];
      _mingguDipilih = [];
      _bulanDipilih = [];
      _mingguPerBulanData = {};
    });

    if (nisn == null) return;

    try {
      final resTahun = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/get_next_tahun.php"),
        body: {'nisn': nisn},
      );
      final dataTahun = jsonDecode(resTahun.body);
      String nextTahun = dataTahun['next_tahun'].toString();

      final resCek = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/cek_minggu.php"),
        body: {'nisn': nisn, 'tahun': nextTahun},
      );
      final dataCek = jsonDecode(resCek.body);

      final resBulan = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/get_next_minggu.php"),
        body: {'nisn': nisn, 'tahun': nextTahun},
      );
      final dataBulan = jsonDecode(resBulan.body);

      if (mounted) {
        setState(() {
          _tahunController.text = nextTahun;
          _bulanController.text = dataBulan['next_bulan'];
          _mingguLunas = List<int>.from(dataBulan['minggu_lunas']);
          _mingguPerBulanData = Map<String, int>.from(dataCek['minggu_per_bulan']);
        });
      }
    } catch (e) {
      debugPrint("Error auto-input: $e");
    }
  }

  void _toggleMinggu(int m) {
    if (_activeSubTab != 'minggu') return;
    setState(() {
      if (_mingguDipilih.contains(m)) {
        _mingguDipilih.removeWhere((x) => x >= m);
      } else {
        for (int i = 1; i <= m; i++) {
          if (!_mingguLunas.contains(i) && !_mingguDipilih.contains(i)) {
            _mingguDipilih.add(i);
          }
        }
      }
      _mingguDipilih.sort();
    });
  }

  void _toggleBulan(String b) {
    if (_activeSubTab != 'bulan') return;
    int idxKlik = _daftarBulanList.indexOf(b);
    setState(() {
      if (_bulanDipilih.contains(b)) {
        for (int i = idxKlik; i < _daftarBulanList.length; i++) {
          _bulanDipilih.remove(_daftarBulanList[i]);
        }
      } else {
        for (int i = 0; i <= idxKlik; i++) {
          String currB = _daftarBulanList[i];
          if ((_mingguPerBulanData[currB] ?? 0) < 4) {
            if (!_bulanDipilih.contains(currB)) _bulanDipilih.add(currB);
          }
        }
      }
    });
  }

  int _calculateAmount() {
    if (_activeSubTab == 'minggu') {
      return _mingguDipilih.length * 5000;
    } else {
      int total = 0;
      for (var b in _bulanDipilih) {
        int sudah = _mingguPerBulanData[b] ?? 0;
        total += (4 - sudah) * 5000;
      }
      return total;
    }
  }

  Future<void> _simpanPemasukan() async {
    if (_selectedNisn == null) {
      _showAlert("Peringatan", "Harap pilih murid terlebih dahulu!");
      return;
    }
    if (_activeSubTab == 'minggu' && _mingguDipilih.isEmpty) {
      _showAlert("Peringatan", "Harap pilih minggu yang ingin dibayar!");
      return;
    }
    if (_activeSubTab == 'bulan' && _bulanDipilih.isEmpty) {
      _showAlert("Peringatan", "Harap pilih bulan yang ingin dibayar!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String endpoint = _activeSubTab == 'minggu' ? 'simpan_pemasukan.php' : 'simpan_masuk_bulan.php';
      final Map<String, String> body = {
        'nisn': _selectedNisn!,
        'tahun': _tahunController.text,
        'keterangan': _keteranganController.text,
        'mode': _activeSubTab,
      };

      if (_activeSubTab == 'minggu') {
        body['bulan'] = _bulanController.text;
        body['minggu'] = jsonEncode(_mingguDipilih);
      } else {
        body['bulan_dipilih'] = jsonEncode(_bulanDipilih);
      }

      final response = await http.post(Uri.parse("http://192.168.18.6/KasKitaAPI/$endpoint"), body: body);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil menyimpan!")));
        _onMuridChanged(null);
        _keteranganController.clear();
        _initData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanPengeluaran() async {
    if (_jmlKeluarController.text.isEmpty || _selectedKategori == null || _tglKeluarController.text.isEmpty) {
      _showAlert("Peringatan", "Harap isi semua field pengeluaran!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/simpan_keluar.php"),
        body: {
          'nisn': widget.userData['id'].toString(),
          'tanggal': _tglKeluarController.text,
          'kategori': _selectedKategori!,
          'jumlah': _jmlKeluarController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        },
      );
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil menyimpan pengeluaran!")));
        _tglKeluarController.clear();
        _jmlKeluarController.clear();
        setState(() => _selectedKategori = null);
        _initData();
      } else {
        _showAlert("Gagal", data['message'] ?? "Terjadi kesalahan server");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan ke server")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9F7),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMainTabs(),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 24),
            _activeTab == 'pemasukan' ? _buildPemasukanForm() : _buildPengeluaranForm(),
            const SizedBox(height: 24),
            _activeTab == 'pemasukan' ? _buildRiwayatPemasukan() : _buildRiwayatPengeluaran(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Buat Transaksi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | ${widget.userData['role']}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildMainTabs() {
    return Row(
      children: [
        Expanded(child: _buildTabBtn('Pemasukan', 'pemasukan', const Color(0xFFA7F3D0))),
        const SizedBox(width: 16),
        Expanded(child: _buildTabBtn('Pengeluaran', 'pengeluaran', const Color(0xFFFFCBCB))),
      ],
    );
  }

  Widget _buildTabBtn(String label, String tab, Color activeColor) {
    bool isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isActive ? activeColor : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey))),
      ),
    );
  }

  Widget _buildStats() {
    bool isPemasukan = _activeTab == 'pemasukan';
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isPemasukan ? 'Total Pemasukan' : 'Total Pengeluaran', 
            isPemasukan ? _totalPemasukan : _totalPengeluaran, 
            isPemasukan ? const Color(0xFFA7F3D0) : const Color(0xFFFFCBCB), 
            isPemasukan ? 'up.png' : 'down.png', 
            '${isPemasukan ? _jmlPemasukan : _jmlPengeluaran} Transaksi'
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Saldo Bersih', 
            _saldoBersih, 
            const Color(0xFF7CB9F3), 
            'cash.png', 
            isPemasukan ? 'Saldo Tersisa' : 'Saldo Kas Tersedia', 
            isBlue: true
          )
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int amount, Color color, String icon, String sub, {bool isBlue = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: isBlue ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isBlue ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 10, color: isBlue ? Colors.white60 : Colors.black45)),
          Align(
            alignment: Alignment.bottomRight, 
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
              child: Image.asset('assets/img/$icon', width: 20, height: 20, color: isBlue ? Colors.white : null)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPemasukanForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buat Transaksi Pemasukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSubTab('Bayar Per Minggu', 'minggu')),
              const SizedBox(width: 12),
              Expanded(child: _buildSubTab('Bayar Per Bulan', 'bulan')),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('Murid'),
          _buildMuridDropdown(),
          const SizedBox(height: 20),
          _buildTahunBulanFields(),
          const SizedBox(height: 20),
          _activeSubTab == 'minggu' ? _buildMingguSection() : _buildBulanSection(),
          const SizedBox(height: 20),
          _buildLabel('Jumlah'),
          _buildReadOnlyField(TextEditingController(text: currencyFormatter.format(_calculateAmount())), 'Rp 0'),
          const SizedBox(height: 20),
          _buildLabel('Keterangan (Opsional)'),
          _buildKeteranganField(),
          const SizedBox(height: 32),
          _buildSimpanMasukBtn(),
        ],
      ),
    );
  }

  Widget _buildPengeluaranForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buat Transaksi Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          _buildLabel('Tanggal'),
          _buildDateField(_tglKeluarController, 'Pilih Tanggal'),
          const SizedBox(height: 20),
          
          _buildLabel('Kategori Pengeluaran'),
          _buildKategoriDropdown(),
          const SizedBox(height: 20),
          
          _buildLabel('Jumlah'),
          _buildJumlahInput(_jmlKeluarController, 'Masukkan Jumlah'),
          const SizedBox(height: 32),
          
          _buildSimpanKeluarBtn(),
        ],
      ),
    );
  }

  Widget _buildSubTab(String text, String value) {
    bool isActive = _activeSubTab == value;
    return GestureDetector(
      onTap: () => setState(() { 
        _activeSubTab = value; 
        _selectedNisn = null; 
        _tahunController.clear(); 
        _bulanController.clear();
        _mingguDipilih = [];
        _bulanDipilih = [];
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey))),
      ),
    );
  }

  Widget _buildMuridDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNisn, hint: const Text('Pilih Murid'), isExpanded: true,
          items: _muridList.map((m) => DropdownMenuItem(value: m['nisn'].toString(), child: Text(m['nama']))).toList(),
          onChanged: _onMuridChanged,
        ),
      ),
    );
  }

  Widget _buildKategoriDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedKategori, hint: const Text('Pilih Kategori'), isExpanded: true,
          items: _kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (val) => setState(() => _selectedKategori = val),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller, readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2100));
        if (pickedDate != null) {
          TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          DateTime finalDateTime;
          if (pickedTime != null) {
            finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          } else {
            final now = DateTime.now();
            finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, now.hour, now.minute, now.second);
          }
          setState(() => controller.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime));
        }
      },
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: const Color(0xFFF1F5F9),
        suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF7CB9F3)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildJumlahInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller, keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
          controller.value = TextEditingValue(
            text: currencyFormatter.format(int.parse(clean)),
            selection: TextSelection.collapsed(offset: currencyFormatter.format(int.parse(clean)).length),
          );
        }
      },
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTahunBulanFields() {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Tahun'), _buildReadOnlyField(_tahunController, 'Tahun')])),
        if (_activeSubTab == 'minggu') ...[
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Bulan'), _buildReadOnlyField(_bulanController, 'Bulan')])),
        ],
      ],
    );
  }

  Widget _buildMingguSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Minggu'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [1, 2, 3, 4].map((m) => _buildMingguBtn(m)).toList()),
      ],
    );
  }

  Widget _buildBulanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Bulan'),
        Wrap(spacing: 8, runSpacing: 8, children: _daftarBulanList.map((b) => _buildBulanBtn(b)).toList()),
      ],
    );
  }

  Widget _buildMingguBtn(int m) {
    bool isLunas = _mingguLunas.contains(m);
    bool isSelected = _mingguDipilih.contains(m);
    Color color = isLunas ? const Color(0xFFA7F3D0) : (isSelected ? Colors.green : (_selectedNisn != null ? const Color(0xFFFFCBCB) : const Color(0xFFE2E8F0)));
    return GestureDetector(
      onTap: isLunas || _selectedNisn == null ? null : () => _toggleMinggu(m),
      child: Container(width: 65, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('M-$m', style: const TextStyle(fontWeight: FontWeight.bold)))),
    );
  }

  Widget _buildBulanBtn(String b) {
    int sudah = _mingguPerBulanData[b] ?? 0;
    bool isLunas = sudah >= 4;
    bool isSelected = _bulanDipilih.contains(b);
    Color color = isLunas ? const Color(0xFFA7F3D0) : (isSelected ? const Color(0xFFA7F3D0) : (_selectedNisn != null ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0)));
    return GestureDetector(
      onTap: isLunas || _selectedNisn == null ? null : () => _toggleBulan(b),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Text(b, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLunas || isSelected ? Colors.black87 : Colors.white))),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  Widget _buildReadOnlyField(TextEditingController controller, String hint) => TextField(controller: controller, readOnly: true, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  Widget _buildKeteranganField() => TextField(controller: _keteranganController, maxLines: 3, decoration: InputDecoration(hintText: 'Tambahkan keterangan...', filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  
  Widget _buildSimpanMasukBtn() => SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading || _selectedNisn == null ? null : _simpanPemasukan, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA7F3D0), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Simpan Pemasukan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))));
  Widget _buildSimpanKeluarBtn() => SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _simpanPengeluaran, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCBCB), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Simpan Pengeluaran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))));

  Widget _buildRiwayatPemasukan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Pemasukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_riwayatMasuk.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey)))),
          ..._riwayatMasuk.map((a) => _buildRiwayatItem(a, true)).toList(),
          const SizedBox(height: 10),
          const Center(child: Text('Lihat Detail', style: TextStyle(color: Color(0xFF7CB9F3), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRiwayatPengeluaran() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_riwayatKeluar.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey)))),
          ..._riwayatKeluar.map((a) => _buildRiwayatItem(a, false)).toList(),
          const SizedBox(height: 10),
          const Center(child: Text('Lihat Detail', style: TextStyle(color: Color(0xFF7CB9F3), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(dynamic a, bool isMasuk) {
    var rawAmount = a['total_jumlah'] ?? a['jumlah'] ?? 0;
    num amount = num.tryParse(rawAmount.toString()) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (isMasuk ? const Color(0xFFA7F3D0) : const Color(0xFFFFCBCB)).withOpacity(0.3), shape: BoxShape.circle),
            child: Image.asset('assets/img/${isMasuk ? "up.png" : "down.png"}', width: 20, height: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMasuk ? 'Pembayaran Kas' : (a['judul'] ?? a['keterangan'] ?? 'Pengeluaran'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(a['nama'] ?? 'Bendahara', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(a['tanggal'] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
          Text('${isMasuk ? "+" : "-"} ${currencyFormatter.format(amount)}', style: TextStyle(color: isMasuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
