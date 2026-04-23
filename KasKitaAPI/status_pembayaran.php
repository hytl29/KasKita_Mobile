<?php
include 'config.php';
header('Content-Type: application/json');

$tahun  = $_POST['tahun'];
$bulan  = $_POST['bulan'];
$minggu = $_POST['minggu'];
$sort   = $_POST['sort'];

// 1. Ambil Semua Murid Aktif
$orderBy = "nama ASC";
if($sort == 'Sort By NISN') $orderBy = "nisn ASC";

$resMurid = mysqli_query($conn, "SELECT nisn, nama FROM murid WHERE status='Aktif' ORDER BY $orderBy");

$list = [];
$sudahCount = 0;
$totalTerkumpul = 0;

while($m = mysqli_fetch_assoc($resMurid)) {
    $nisn = $m['nisn'];
    // Cek apakah murid ini sudah bayar di minggu/bulan/tahun tersebut
    $qCek = mysqli_query($conn, "SELECT jumlah FROM transaksi WHERE nisn='$nisn' AND tahun='$tahun' AND bulan='$bulan' AND minggu='$minggu' AND jenis='Masuk'");
    
    if(mysqli_num_rows($qCek) > 0) {
        $trans = mysqli_fetch_assoc($qCek);
        $m['status_bayar'] = 'Sudah Bayar';
        $sudahCount++;
        $totalTerkumpul += (int)$trans['jumlah'];
    } else {
        $m['status_bayar'] = 'Belum Bayar';
    }
    $list[] = $m;
}

// Logika sorting tambahan untuk Status jika dipilih
if($sort == 'Status: Sudah Bayar') {
    usort($list, function($a, $b) { return strcmp($b['status_bayar'], $a['status_bayar']); });
} else if($sort == 'Status: Belum Bayar') {
    usort($list, function($a, $b) { return strcmp($a['status_bayar'], $b['status_bayar']); });
}

$totalMurid = count($list);

echo json_encode([
    "summary" => [
        "sudah_bayar" => $sudahCount,
        "belum_bayar" => $totalMurid - $sudahCount,
        "total_terkumpul" => $totalTerkumpul,
        "total_murid" => $totalMurid
    ],
    "murid" => $list
]);
?>