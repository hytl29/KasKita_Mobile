<?php
include 'config.php';
error_reporting(0);
header('Content-Type: application/json');

$nisn = $_POST['nisn']; // NISN Bendahara dari Flutter
$tanggal = $_POST['tanggal'];
$kategori = $_POST['kategori'];
$jumlah = $_POST['jumlah'];

// Hitung Tahun dan Bulan otomatis dari tanggal
$tahun = date('Y', strtotime($tanggal));
$bulanMap = [
    '01'=>'Januari', '02'=>'Februari', '03'=>'Maret', '04'=>'April',
    '05'=>'Mei', '06'=>'Juni', '07'=>'Juli', '08'=>'Agustus',
    '09'=>'September', '10'=>'Oktober', '11'=>'November', '12'=>'Desember'
];
$bulan = $bulanMap[date('m', strtotime($tanggal))];

$q = mysqli_query($conn, "INSERT INTO transaksi (nisn, tanggal, tahun, bulan, jenis, jumlah, keterangan) 
                          VALUES ('$nisn', '$tanggal', '$tahun', '$bulan', 'Keluar', '$jumlah', '$kategori')");

if($q) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => mysqli_error($conn)]);
}
?>