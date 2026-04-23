<?php
include 'config.php';
$nisn = $_POST['nisn'];
$tahun = $_POST['tahun'];

$daftarBulan = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
$mingguPerBulan = [];

foreach($daftarBulan as $b) {
    $q = mysqli_query($conn, "SELECT COUNT(DISTINCT minggu) as total FROM transaksi WHERE nisn='$nisn' AND tahun='$tahun' AND bulan='$b' AND jenis='Masuk'");
    $res = mysqli_fetch_assoc($q);
    $mingguPerBulan[$b] = (int)($res['total'] ?? 0);
}

echo json_encode(["minggu_per_bulan" => $mingguPerBulan]);
?>