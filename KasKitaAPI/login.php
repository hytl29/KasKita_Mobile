<?php
header('Content-Type: application/json');
include 'config.php';

// Mencegah munculnya error teks/HTML agar tidak merusak format JSON
error_reporting(0);

// Mengambil data dari POST
$u = isset($_POST['username']) ? mysqli_real_escape_string($conn, $_POST['username']) : '';
$p = isset($_POST['password']) ? mysqli_real_escape_string($conn, $_POST['password']) : '';

if (empty($u) || empty($p)) {
    echo json_encode(["status" => "error", "message" => "NISN / NIK dan Password tidak boleh kosong!"]);
    exit;
}

if (!preg_match('/^[0-9]{10}$|^[0-9]{16}$/', $u)) {
    echo json_encode(["status" => "error", "message" => "NISN / NIK harus 10 atau 16 digit angka!"]);
    exit;
}

// 1. Cek di tabel Murid (menggunakan nisn)
$queryMurid = "SELECT * FROM murid WHERE nisn = '$u' AND password = '$p' AND status = 'Aktif'";
$resultMurid = mysqli_query($conn, $queryMurid);

if ($resultMurid && mysqli_num_rows($resultMurid) > 0) {
    $user = mysqli_fetch_assoc($resultMurid);
    echo json_encode([
        "status" => "success",
        "message" => "Login berhasil sebagai Siswa",
        "user" => [
            "id" => $user['nisn'],
            "nama" => $user['nama'],
            "role" => $user['role'],        
            "kelas" => $user['kelas']
        ]
    ]);
    exit;
}

// 2. Jika tidak ada di murid, cek di tabel Walikelas (menggunakan nik)
$queryWali = "SELECT * FROM walikelas WHERE nip = '$u' AND password = '$p' AND status = 'Aktif'";
$resultWali = mysqli_query($conn, $queryWali);

if ($resultWali && mysqli_num_rows($resultWali) > 0) {
    $user = mysqli_fetch_assoc($resultWali);
    echo json_encode([
        "status" => "success",
        "message" => "Login berhasil sebagai Wali Kelas",
        "user" => [
            "id" => $user['nip'],
            "nama" => $user['nama'],
            "role" => "Walikelas",
        ]
    ]);
    exit;
}

// 3. Jika keduanya tidak ditemukan
echo json_encode([
    "status" => "error",
    "message" => "NISN/NIK atau Password salah, atau akun tidak aktif"
]);
?>