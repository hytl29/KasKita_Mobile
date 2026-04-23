<?php
include 'config.php';
header('Content-Type: application/json');

$type = $_POST['type'] ?? 'Semua Transaksi';
$tahun = $_POST['tahun'];
$bulan = $_POST['bulan'];

// 1. Total Saldo Global
$qSaldo = mysqli_query($conn, "SELECT SUM(CASE WHEN jenis='Masuk' THEN jumlah ELSE 0 END) - SUM(CASE WHEN jenis='Keluar' THEN jumlah ELSE 0 END) as saldo FROM transaksi");
$saldoGlobal = mysqli_fetch_assoc($qSaldo)['saldo'] ?? 0;

// 2. Query Transaksi dengan Grouping Minggu & Filter
$where = "WHERE YEAR(t.tanggal)='$tahun' AND MONTHNAME(t.tanggal)='$bulan'";
if($type == 'Pemasukan') $where .= " AND t.jenis='Masuk'";
if($type == 'Pengeluaran') $where .= " AND t.jenis='Keluar'";

$query = "SELECT t.tanggal, t.jenis, t.keterangan, t.bulan, t.tahun, m.nama, 
          SUM(t.jumlah) as total_jumlah,
          GROUP_CONCAT(DISTINCT t.minggu ORDER BY t.minggu ASC SEPARATOR ', ') as minggu_list
          FROM transaksi t 
          LEFT JOIN murid m ON t.nisn = m.nisn 
          $where 
          GROUP BY t.tanggal, t.nisn, t.jenis, t.bulan, t.tahun
          ORDER BY t.tanggal DESC";

$res = mysqli_query($conn, $query);
$transaksi = [];
$inF = 0; $outF = 0;

while($row = mysqli_fetch_assoc($res)) {
    $row['jenis'] == 'Masuk' ? $inF += (int)$row['total_jumlah'] : $outF += (int)$row['total_jumlah'];
    $transaksi[] = [
        "jenis" => $row['jenis'],
        "nama" => $row['nama'] ?? 'Bendahara',
        "keterangan" => $row['keterangan'],
        "jumlah" => (int)$row['total_jumlah'],
        "tanggal" => date('d M Y H:i', strtotime($row['tanggal'])),
        "bulan" => $row['bulan'],
        "tahun" => $row['tahun'],
        "minggu_list" => $row['minggu_list']
    ];
}

echo json_encode([
    "summary" => ["saldo" => (int)$saldoGlobal, "pemasukan_filter" => $inF, "pengeluaran_filter" => $outF, "total_transaksi" => count($transaksi)],
    "transaksi" => $transaksi
]);
?>