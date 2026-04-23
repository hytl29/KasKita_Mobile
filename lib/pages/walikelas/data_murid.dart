import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DataMuridPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DataMuridPage({super.key, required this.userData});

  @override
  State<DataMuridPage> createState() => _DataMuridPageState();
}

class _DataMuridPageState extends State<DataMuridPage> {
  bool _isLoading = true;
  List<dynamic> _muridList = [];
  List<dynamic> _filteredList = [];
  Map<String, dynamic> _summary = {'total': 0, 'aktif': 0, 'non_aktif': 0};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("http://192.168.18.6/KasKitaAPI/get_data_murid.php"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _muridList = data['murid'];
          _filteredList = _muridList;
          _summary = data['summary'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error data murid: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredList = _muridList.where((m) {
        return m['nama'].toString().toLowerCase().contains(query.toLowerCase()) ||
               m['nisn'].toString().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteMurid(String nisn) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.18.6/KasKitaAPI/delete_murid.php"),
        body: {'nisn': nisn},
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        _fetchData();
      }
    } catch (e) {
      debugPrint("Error delete: $e");
    }
  }

  void _showForm({Map<String, dynamic>? murid}) {
    final nisnController = TextEditingController(text: murid?['nisn'] ?? '');
    final namaController = TextEditingController(text: murid?['nama'] ?? '');
    final passwordController = TextEditingController(text: murid?['password'] ?? '');
    String status = murid?['status'] ?? 'Aktif';
    String role = murid?['role'] ?? 'Siswa';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(murid == null ? 'Tambah Murid' : 'Edit Murid'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nisnController, decoration: const InputDecoration(labelText: 'NISN'), readOnly: murid != null),
              TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Aktif', 'Non-Aktif'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => status = v!,
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Siswa', 'Bendahara', 'Ketua Kelas'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => role = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse("http://192.168.18.6/KasKitaAPI/upsert_murid.php"),
                body: {
                  'nisn': nisnController.text,
                  'nama': namaController.text,
                  'password': passwordController.text,
                  'status': status,
                  'role': role,
                  'is_edit': murid != null ? '1' : '0',
                },
              );
              if (jsonDecode(response.body)['status'] == 'success') {
                Navigator.pop(context);
                _fetchData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9F7),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF7CB9F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildSearchBar(),
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
        const Text('Data Murid', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7CB9F3))),
        const SizedBox(height: 4),
        Text('${widget.userData['nama']} | Wali Kelas', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Semua Murid', '${_summary['total']}', 'Siswa Terdaftar', const Color(0xFF7CB9F3), Icons.person)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Murid Aktif', '${_summary['aktif']}', 'Status Aktif', const Color(0xFFA7F3D0), Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Murid Non-Aktif', '${_summary['non_aktif']}', 'Status Non-Aktif', const Color(0xFFFFCBCB), Icons.cancel_outlined)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Icon(icon, size: 24, color: Colors.black26),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterData,
      decoration: InputDecoration(
        hintText: 'Cari Nama, NISN, atau Status...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                SizedBox(width: 30, child: Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Nama Murid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                SizedBox(width: 100, child: Text('NISN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                SizedBox(width: 60, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final m = _filteredList[index];
                bool isAktif = m['status'] == 'Aktif';
                return InkWell(
                  onLongPress: () => _showDeleteDialog(m['nisn']),
                  onTap: () => _showForm(murid: m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text('${index + 1}')),
                        Expanded(child: Text(m['nama'], style: const TextStyle(fontWeight: FontWeight.w500))),
                        SizedBox(width: 100, child: Text(m['nisn'])),
                        SizedBox(
                          width: 60,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(color: isAktif ? const Color(0xFFA7F3D0).withOpacity(0.3) : const Color(0xFFFFCBCB).withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                            child: Text(isAktif ? 'Aktif' : 'Non', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAktif ? Colors.green : Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String nisn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus murid ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () { _deleteMurid(nisn); Navigator.pop(context); }, child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
