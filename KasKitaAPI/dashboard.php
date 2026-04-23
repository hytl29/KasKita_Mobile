<?php
header('Content-Type: application/json');
include 'config.php';
error_reporting(0);

// 1. Hitung Saldo, Masuk, Keluar
$qMasuk = mysqli_query($conn, "SELECT SUM(jumlah) AS total FROM transaksi WHERE jenis='Masuk'");
$masuk = mysqli_fetch_assoc($qMasuk)['total'] ?? 0;

$qKeluar = mysqli_query($conn, "SELECT SUM(jumlah) AS total FROM transaksi WHERE jenis='Keluar'");
$keluar = mysqli_fetch_assoc($qKeluar)['total'] ?? 0;

$saldo = $masuk - $keluar;

// 2. Info Waktu & Status Pembayaran
$mingguNow = min(4, (int) ceil(date('j') / 7));
$bulanMap = [1=>'Januari', 2=>'Februari', 3=>'Maret', 4=>'April', 5=>'Mei', 6=>'Juni', 7=>'Juli', 8=>'Agustus', 9=>'September', 10=>'Oktober', 11=>'November', 12=>'Desember'];
$bulanNow = $bulanMap[(int) date('n')];
$tahunNow = date('Y');

$qSudah = mysqli_query($conn, "SELECT COUNT(DISTINCT nisn) AS total FROM transaksi WHERE jenis = 'Masuk' AND bulan = '$bulanNow' AND tahun = '$tahunNow' AND minggu = '$mingguNow'");
$sudahBayar = mysqli_fetch_assoc($qSudah)['total'] ?? 0;

$qTotal = mysqli_query($conn, "SELECT COUNT(*) AS total FROM murid WHERE status = 'Aktif'");
$totalMurid = mysqli_fetch_assoc($qTotal)['total'] ?? 0;

// 3. Aktivitas Terbaru
$qAktivitas = mysqli_query($conn, "
    SELECT * FROM (
        SELECT 'Masuk' AS jenis, m.nama, t.tanggal, t.bulan, t.tahun, SUM(t.jumlah) AS total_jumlah, 
        GROUP_CONCAT(DISTINCT t.minggu ORDER BY t.minggu ASC) AS minggu_list, 'Pembayaran Kas' AS judul
        FROM transaksi t JOIN murid m ON t.nisn = m.nisn WHERE t.jenis = 'Masuk'
        GROUP BY t.nisn, t.tanggal, t.bulan, t.tahun
        UNION ALL
        SELECT 'Keluar' AS jenis, m.nama, t.tanggal, t.bulan, t.tahun, t.jumlah AS total_jumlah, 
        NULL AS minggu_list, t.keterangan AS judul
        FROM transaksi t JOIN murid m ON t.nisn = m.nisn WHERE t.jenis = 'Keluar'
    ) aktivitas ORDER BY tanggal DESC LIMIT 5
");

$aktivitas = [];
while($row = mysqli_fetch_assoc($qAktivitas)) {
    $aktivitas[] = [
        "jenis" => $row['jenis'],
        "nama" => $row['nama'],
        "judul" => $row['judul'],
        "total_jumlah" => (int)$row['total_jumlah'],
        "tanggal" => date('d M Y H:i', strtotime($row['tanggal'])),
        "bulan" => $row['bulan'],
        "tahun" => $row['tahun'],
        "minggu_list" => $row['minggu_list']
    ];
}

echo json_encode([
    "saldo" => (int)$saldo,
    "pemasukan" => (int)$masuk,
    "pengeluaran" => (int)$keluar,
    "sudah_bayar" => (int)$sudahBayar,
    "total_murid" => (int)$totalMurid,
    "aktivitas" => $aktivitas
]);
?>
