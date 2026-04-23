<?php
include 'config.php';

$nisn = $_POST['nisn'];
$tahun = $_POST['tahun'];
$ket = $_POST['keterangan'] ?? 'Pembayaran Kas';
$mode = $_POST['mode'];

$now = date('Y-m-d H:i:s');

if ($mode == 'minggu') {
    $bulan = $_POST['bulan'];
    $minggu = json_decode($_POST['minggu']);
    foreach ($minggu as $m) {
        mysqli_query($conn, "INSERT INTO transaksi (nisn, tanggal, tahun, bulan, minggu, jenis, jumlah, keterangan) 
        VALUES ('$nisn', '$now', '$tahun', '$bulan', '$m', 'Masuk', 5000, '$ket')");
    }
} else {
    $bulanDipilih = json_decode($_POST['bulan_dipilih']);
    foreach ($bulanDipilih as $b) {
        $qCek = mysqli_query($conn, "SELECT minggu FROM transaksi WHERE nisn='$nisn' AND tahun='$tahun' AND bulan='$b' AND jenis='Masuk'");
        $sudah = [];
        while($r = mysqli_fetch_assoc($qCek)) { $sudah[] = (int)$r['minggu']; }

        for ($m = 1; $m <= 4; $m++) {
            if (!in_array($m, $sudah)) {
                // GUNAKAN VARIABEL $now YANG SAMA
                mysqli_query($conn, "INSERT INTO transaksi (nisn, tanggal, tahun, bulan, minggu, jenis, jumlah, keterangan) 
                VALUES ('$nisn', '$now', '$tahun', '$b', '$m', 'Masuk', 5000, '$ket')");
            }
        }
    }
}
echo json_encode(["status" => "success"]);
?>