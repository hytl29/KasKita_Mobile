<?php
include 'config.php';
header('Content-Type: application/json');

$nisn = $_POST['nisn'];
$tahun = $_POST['tahun'];

$months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
$status = [];

foreach($months as $m) {
    // Cek minggu 1 sampai 4
    $weeks = [];
    for($i=1; $i<=4; $i++) {
        $q = mysqli_query($conn, "SELECT id_transaksi FROM transaksi WHERE nisn='$nisn' AND tahun='$tahun' AND bulan='$m' AND minggu='$i' AND jenis='Masuk'");
        $weeks[] = (mysqli_num_rows($q) > 0) ? 1 : 0;
    }
    $status[$m] = $weeks;
}

echo json_encode(["status" => $status]);
?>