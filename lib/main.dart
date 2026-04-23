import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'pages/bendahara/dashboard.dart';
import 'pages/bendahara/buat_transaksi.dart';
import 'pages/bendahara/status_pembayaran.dart';
import 'pages/bendahara/arus_kas.dart';
import 'pages/bendahara/laporan.dart';
import 'pages/walikelas/data_murid.dart';
import 'pages/ketua_kelas/dashboard.dart';
import 'pages/siswa/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KasKita',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Sans-Serif',
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  final String apiUrl = "http://192.168.18.6/KasKitaAPI/login.php";

  Future<void> _login() async {
    final String u = _usernameController.text.trim();
    final String p = _passwordController.text.trim();

    if (u.isEmpty || p.isEmpty) {
      _showError('NISN / NIK dan Password tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'username': u, 'password': p},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigation(userData: data['user']),
            ),
          );
        } else {
          _showError(data['message'] ?? 'Login gagal');
        }
      } else {
        _showError('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal terhubung ke server. Cek IP & Jaringan WiFi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Gagal'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9F7),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 75, height: 75,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFF7CB9F3), shape: BoxShape.circle),
                        child: Image.asset('assets/img/wallet.png', color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text('Sistem Kas Kelas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      const Align(alignment: Alignment.centerLeft, child: Text("NISN / NIK", style: TextStyle(fontWeight: FontWeight.bold))),
                      TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'Masukkan NISN / NIK Anda', filled: true, fillColor: Color(0xFFF1F5F9), border: InputBorder.none)),
                      const SizedBox(height: 20),
                      const Align(alignment: Alignment.centerLeft, child: Text("Password", style: TextStyle(fontWeight: FontWeight.bold))),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Masukkan Password Anda',
                          filled: true, fillColor: const Color(0xFFF1F5F9), border: InputBorder.none,
                          suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureText = !_obscureText)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7CB9F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Color(0xFF7CB9F3)))),
        ],
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MainNavigation({super.key, required this.userData});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _buildNavigation();
  }

  void _buildNavigation() {
    final role = widget.userData['role']?.toString().toLowerCase().replaceAll('_', ' ') ?? '';
    final bool isBendahara = role == 'bendahara';
    final bool isKetua = role == 'ketua kelas';
    final bool isSiswa = role == 'siswa';
    final bool isWali = role == 'walikelas' || role == 'wali kelas';

    Widget dashboard;
    if (isSiswa) {
      dashboard = DashboardSiswaPage(userData: widget.userData);
    } else if (isKetua || isWali) {
      dashboard = DashboardKetuaPage(userData: widget.userData);
    } else {
      dashboard = DashboardPage(userData: widget.userData);
    }

    if (isSiswa) {
      _pages = [dashboard, ArusKasPage(userData: widget.userData)];
      _navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Arus'),
      ];
    } else {
      _pages = [
        dashboard,
        if (isWali) DataMuridPage(userData: widget.userData),
        if (isBendahara) BuatTransaksiPage(userData: widget.userData),
        StatusPembayaranPage(userData: widget.userData),
        ArusKasPage(userData: widget.userData),
        LaporanPage(userData: widget.userData),
      ];

      _navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
        if (isWali) const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Data Murid'),
        if (isBendahara) const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Transaksi'),
        const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Status'),
        const BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Arus'),
        const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Laporan'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7CB9F3),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Image.asset('assets/img/wallet.png', color: Colors.white),
          ),
        ),
        title: const Text('KasKita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Image.asset('assets/img/logout.png', color: Colors.red, width: 24, height: 24),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF7CB9F3),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }
}
